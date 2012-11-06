// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

class SsaCodeGeneratorTask extends CompilerTask {

  final JavaScriptBackend backend;

  SsaCodeGeneratorTask(JavaScriptBackend backend)
      : this.backend = backend,
        super(backend.compiler);
  String get name => 'SSA code generator';
  NativeEmitter get nativeEmitter => backend.emitter.nativeEmitter;


  js.Fun buildJavaScriptFunction(FunctionElement element,
                                 List<js.Parameter> parameters,
                                 js.Block body) {
    FunctionExpression expression =
        element.implementation.parseNode(backend.compiler);
    js.Fun result = new js.Fun(parameters, body);
    // TODO(johnniwinther): remove the 'element.patch' hack.
    Element sourceElement = element.patch == null ? element : element.patch;
    SourceFile sourceFile = sourceElement.getCompilationUnit().script.file;
    // TODO(podivilov): find the right sourceFile here and remove offset checks
    // below.
    if (expression.getBeginToken().charOffset < sourceFile.text.length) {
      result.sourcePosition = new SourceFileLocation(
          sourceFile, expression.getBeginToken());
    }
    if (expression.getEndToken().charOffset < sourceFile.text.length) {
      result.endSourcePosition = new SourceFileLocation(
          sourceFile, expression.getEndToken());
    }
    return result;
  }

  CodeBuffer prettyPrint(js.Node node, {bool allowVariableMinification: true}) {
    var code = js.prettyPrint(
        node, compiler, allowVariableMinification: allowVariableMinification);
    return code;
  }

  CodeBuffer generateCode(WorkItem work, HGraph graph) {
    if (work.element.isField()) {
      return generateLazyInitializer(work, graph);
    } else {
      return generateMethod(work, graph);
    }
  }

  CodeBuffer generateLazyInitializer(work, graph) {
    return measure(() {
      compiler.tracer.traceGraph("codegen", graph);
      List<js.Parameter> parameters = <js.Parameter>[];
      SsaOptimizedCodeGenerator codegen = new SsaOptimizedCodeGenerator(
          backend, work, parameters, new Map<Element, String>());
      codegen.visitGraph(graph);
      js.Block body = codegen.body;
      js.Fun fun = new js.Fun(parameters, body);
      return prettyPrint(fun);
    });
  }

  CodeBuffer generateMethod(WorkItem work, HGraph graph) {
    return measure(() {
      JavaScriptItemCompilationContext context = work.compilationContext;
      HTypeMap types = context.types;
      graph.exit.predecessors.forEach((block) {
        assert(block.last is HGoto || block.last is HReturn);
        if (block.last is HReturn) {
          backend.registerReturnType(work.element, types[block.last.inputs[0]]);
        } else {
          backend.registerReturnType(work.element, HType.NULL);
        }
      });
      compiler.tracer.traceGraph("codegen", graph);
      Map<Element, String> parameterNames = getParameterNames(work);
      // Use [work.element] to ensure that the parameter element come from
      // the declaration.
      FunctionElement function = work.element;
      function.computeSignature(compiler).forEachParameter((element) {
        compiler.enqueuer.codegen.addToWorkList(element, work.resolutionTree);
      });
      List<js.Parameter> parameters = <js.Parameter>[];
      parameterNames.forEach((element, name) {
        parameters.add(new js.Parameter(name));
      });
      addBackendParameters(work.element, parameters, parameterNames);
      String parametersString = Strings.join(parameterNames.values, ", ");
      SsaOptimizedCodeGenerator codegen = new SsaOptimizedCodeGenerator(
          backend, work, parameters, parameterNames);
      codegen.visitGraph(graph);

      FunctionElement element = work.element;
      js.Block body;
      ClassElement enclosingClass = element.getEnclosingClass();
      bool allowVariableMinification;
      if (element.isInstanceMember()
          && enclosingClass.isNative()
          && native.isOverriddenMethod(
              element, enclosingClass, nativeEmitter)) {
        // Record that this method is overridden. In case of optional
        // arguments, the emitter will generate stubs to handle them,
        // and needs to know if the method is overridden.
        nativeEmitter.overriddenMethods.add(element);
        StringBuffer buffer = new StringBuffer();
        String codeString = prettyPrint(codegen.body).toString();
        native.generateMethodWithPrototypeCheckForElement(
            compiler, buffer, element, codeString, parametersString);
        js.Node nativeCode = new js.LiteralStatement(buffer.toString());
        body = new js.Block(<js.Statement>[nativeCode]);
        allowVariableMinification = false;
      } else {
        body = codegen.body;
        allowVariableMinification = !codegen.visitedForeignCode;
      }
      js.Fun fun = buildJavaScriptFunction(element, parameters, body);
      return prettyPrint(fun,
                         allowVariableMinification: allowVariableMinification);
    });
  }

  void addBackendParameter(Element element,
                           List<js.Parameter> parameters,
                           Map<Element, String> parameterNames) {
    String name = element.name.slowToString();
    String prefix = '';
    // Avoid collisions with real parameters of the method.
    do {
      name = JsNames.getValid('$prefix$name');
      prefix = '\$$prefix';
    } while (parameterNames.containsValue(name));
    parameterNames[element] = name;
    parameters.add(new js.Parameter(name));
  }

  void addBackendParameters(Element element,
                            List<js.Parameter> parameters,
                            Map<Element, String> parameterNames) {
    // TODO(ngeoffray): We should infer this information from the
    // graph, instead of recomputing what the builder did.
    if (element.isConstructor()) {
      // Put the type parameters.
      ClassElement cls = element.enclosingElement;
      if (!compiler.world.needsRti(cls)) return;
      cls.typeVariables.forEach((TypeVariableType typeVariable) {
        addBackendParameter(typeVariable.element, parameters, parameterNames);
      });
    } else if (element.isGenerativeConstructorBody()) {
      // Put the parameter checks parameters.
      Node node = element.implementation.parseNode(compiler);
      ClosureClassMap closureData =
          compiler.closureToClassMapper.getMappingForNestedFunction(node);
      FunctionElement functionElement = element;
      FunctionSignature params = functionElement.computeSignature(compiler);
      TreeElements elements =
          compiler.enqueuer.resolution.getCachedElements(element);
      params.orderedForEachParameter((Element element) {
        if (elements.isParameterChecked(element)) {
          Element checkResultElement =
              closureData.parametersWithSentinel[element];
          addBackendParameter(checkResultElement, parameters, parameterNames);
        }
      });
      // Put the box parameter.
      ClosureScope scopeData = closureData.capturingScopes[node];
      if (scopeData != null) {
        addBackendParameter(scopeData.boxElement, parameters, parameterNames);
      }
    }
  }

  CodeBuffer generateBailoutMethod(WorkItem work, HGraph graph) {
    return measure(() {
      compiler.tracer.traceGraph("codegen-bailout", graph);

      Map<Element, String> parameterNames = getParameterNames(work);
      List<js.Parameter> parameters = <js.Parameter>[];
      parameterNames.forEach((element, name) {
        parameters.add(new js.Parameter(name));
      });
      addBackendParameters(work.element, parameters, parameterNames);

      SsaUnoptimizedCodeGenerator codegen = new SsaUnoptimizedCodeGenerator(
          backend, work, parameters, parameterNames);
      codegen.visitGraph(graph);

      js.Block body = new js.Block(<js.Statement>[]);
      if (codegen.setup != null) body.statements.add(codegen.setup);
      body.statements.add(codegen.body);
      js.Fun fun =
          buildJavaScriptFunction(work.element, codegen.newParameters, body);
      return prettyPrint(fun);
    });
  }

  Map<Element, String> getParameterNames(WorkItem work) {
    // Make sure the map preserves insertion order, so that fetching
    // the values will keep the order of parameters.
    Map<Element, String> parameterNames = new LinkedHashMap<Element, String>();
    FunctionElement function = work.element.implementation;

    // The dom/html libraries have inline JS code that reference
    // parameter names directly. Long-term such code will be rejected.
    // Now, just don't mangle the parameter name.
    FunctionSignature signature = function.computeSignature(compiler);
    signature.orderedForEachParameter((Element element) {
      parameterNames[element] = function.isNative()
          ? element.name.slowToString()
          : JsNames.getValid('${element.name.slowToString()}');
    });
    return parameterNames;
  }
}

// Stop-gap until the core classes have such a class.
class OrderedSet<T> {
  final LinkedHashMap<T, bool> map = new LinkedHashMap<T, bool>();

  void add(T x) {
    if (!map.containsKey(x)) {
      map[x] = true;
    }
  }

  bool contains(T x) => map.containsKey(x);

  bool remove(T x) => map.remove(x) != null;

  bool get isEmpty => map.isEmpty;

  void forEach(f) => map.keys.forEach(f);

  T get first => map.keys.iterator().next();

  get length => map.length;
}

typedef void ElementAction(Element element);

abstract class SsaCodeGenerator implements HVisitor, HBlockInformationVisitor {
  /**
   * Returned by [expressionType] to tell how code can be generated for
   * a subgraph.
   * - [TYPE_STATEMENT] means that the graph must be generated as a statement,
   * which is always possible.
   * - [TYPE_EXPRESSION] means that the graph can be generated as an expression,
   * or possibly several comma-separated expressions.
   * - [TYPE_DECLARATION] means that the graph can be generated as an
   * expression, and that it only generates expressions of the form
   *   variable = expression
   * which are also valid as parts of a "var" declaration.
   */
  static const int TYPE_STATEMENT = 0;
  static const int TYPE_EXPRESSION = 1;
  static const int TYPE_DECLARATION = 2;

  /**
   * Whether we are currently generating expressions instead of statements.
   * This includes declarations, which are generated as expressions.
   */
  bool isGeneratingExpression = false;

  bool visitedForeignCode = false;

  final JavaScriptBackend backend;
  final WorkItem work;
  final HTypeMap types;

  final Set<HInstruction> generateAtUseSite;
  final Set<HInstruction> controlFlowOperators;
  final Map<Element, ElementAction> breakAction;
  final Map<Element, ElementAction> continueAction;
  final Map<Element, String> parameterNames;

  js.Block currentContainer;
  js.Block get body => currentContainer;
  List<js.Expression> expressionStack;
  List<js.Block> oldContainerStack;

  /**
   * Contains the names of the instructions, as well as the parallel
   * copies to perform on block transitioning.
   */
  VariableNames variableNames;
  bool shouldGroupVarDeclarations = false;

  /**
   * While generating expressions, we can't insert variable declarations.
   * Instead we declare them at the start of the function.  When minifying
   * we do this most of the time, because it reduces the size unless there
   * is only one variable.
   */
  final OrderedSet<String> collectedVariableDeclarations;

  /**
   * Set of variables and parameters that have already been declared.
   */
  final Set<String> declaredLocals;

  Element equalsNullElement;
  Element boolifiedEqualsNullElement;
  int indent = 0;
  HGraph currentGraph;
  HBasicBlock currentBlock;

  // Records a block-information that is being handled specially.
  // Used to break bad recursion.
  HBlockInformation currentBlockInformation;
  // The subgraph is used to delimit traversal for some constructions, e.g.,
  // if branches.
  SubGraph subGraph;

  SsaCodeGenerator(this.backend,
                   WorkItem work,
                   this.parameterNames)
    : this.work = work,
      this.types =
          (work.compilationContext as JavaScriptItemCompilationContext).types,
      declaredLocals = new Set<String>(),
      collectedVariableDeclarations = new OrderedSet<String>(),
      currentContainer = new js.Block.empty(),
      expressionStack = <js.Expression>[],
      oldContainerStack = <js.Block>[],
      generateAtUseSite = new Set<HInstruction>(),
      controlFlowOperators = new Set<HInstruction>(),
      breakAction = new Map<Element, ElementAction>(),
      continueAction = new Map<Element, ElementAction>();

  LibraryElement get currentLibrary => work.element.getLibrary();
  Compiler get compiler => backend.compiler;
  NativeEmitter get nativeEmitter => backend.emitter.nativeEmitter;
  Enqueuer get world => backend.compiler.enqueuer.codegen;

  bool isGenerateAtUseSite(HInstruction instruction) {
    return generateAtUseSite.contains(instruction);
  }

  bool isNonNegativeInt32Constant(HInstruction instruction) {
    if (instruction.isConstantInteger()) {
      HConstant constantInstruction = instruction;
      PrimitiveConstant primitiveConstant = constantInstruction.constant;
      int value = primitiveConstant.value;
      if (value >= 0 && value < (1 << 31)) {
        return true;
      }
    }
    return false;
  }

  bool hasNonBitOpUser(HInstruction instruction, Set<HPhi> phiSet) {
    for (HInstruction user in instruction.usedBy) {
      if (user is HPhi) {
        if (!phiSet.contains(user)) {
          phiSet.add(user);
          if (hasNonBitOpUser(user, phiSet)) return true;
        }
      } else if (user is! HBitNot && user is! HBinaryBitOp) {
        return true;
      }
    }
    return false;
  }

  // We want the outcome of bit-operations to be positive. However, if
  // the result of a bit-operation is only used by other bit
  // operations we do not have to convert to an unsigned
  // integer. Also, if we are using & with a positive constant we know
  // that the result is positive already and need no conversion.
  bool requiresUintConversion(HInstruction instruction) {
    if (instruction is HBitAnd) {
      HBitAnd bitAnd = instruction;
      if (isNonNegativeInt32Constant(bitAnd.left) ||
          isNonNegativeInt32Constant(bitAnd.right)) {
        return false;
      }
    }
    return hasNonBitOpUser(instruction, new Set<HPhi>());
  }

  /**
   * If the [instruction] is not `null` it will be used to attach the position
   * to the [statement].
   */
  void pushStatement(js.Statement statement, [HInstruction instruction]) {
    assert(expressionStack.isEmpty);
    if (instruction != null) {
      attachLocation(statement, instruction);
    }
    currentContainer.statements.add(statement);
  }

  void insertStatementAtStart(js.Statement statement) {
    currentContainer.statements.insertRange(0, 1, statement);
  }

  /**
   * If the [instruction] is not `null` it will be used to attach the position
   * to the [expression].
   */
  pushExpressionAsStatement(js.Expression expression,
                            [HInstruction instruction]) {
    pushStatement(new js.ExpressionStatement(expression), instruction);
  }

  /**
   * If the [instruction] is not `null` it will be used to attach the position
   * to the [expression].
   */
  push(js.Expression expression, [HInstruction instruction]) {
    if (instruction != null) {
      attachLocation(expression, instruction);
    }
    expressionStack.add(expression);
  }

  js.Expression pop() {
    return expressionStack.removeLast();
  }

  attachLocationToLast(HInstruction instruction) {
    attachLocation(expressionStack.last, instruction);
  }

  js.Node attachLocation(js.Node jsNode, HInstruction instruction) {
    jsNode.sourcePosition = instruction.sourcePosition;
    return jsNode;
  }

  js.Node attachLocationRange(js.Node jsNode,
                              SourceFileLocation sourcePosition,
                              SourceFileLocation endSourcePosition) {
    jsNode.sourcePosition = sourcePosition;
    jsNode.endSourcePosition = endSourcePosition;
    return jsNode;
  }

  visitTypeGuard(HTypeGuard node);
  visitBailoutTarget(HBailoutTarget node);

  beginGraph(HGraph graph);
  endGraph(HGraph graph);

  beginLoop(HBasicBlock block);
  endLoop(HBasicBlock block);
  handleLoopCondition(HLoopBranch node);

  preLabeledBlock(HLabeledBlockInformation labeledBlockInfo);
  startLabeledBlock(HLabeledBlockInformation labeledBlockInfo);
  endLabeledBlock(HLabeledBlockInformation labeledBlockInfo);

  void preGenerateMethod(HGraph graph) {
    new SsaInstructionMerger(types, generateAtUseSite).visitGraph(graph);
    new SsaConditionMerger(
        types, generateAtUseSite, controlFlowOperators).visitGraph(graph);
    SsaLiveIntervalBuilder intervalBuilder =
        new SsaLiveIntervalBuilder(compiler, generateAtUseSite);
    intervalBuilder.visitGraph(graph);
    SsaVariableAllocator allocator = new SsaVariableAllocator(
        compiler,
        intervalBuilder.liveInstructions,
        intervalBuilder.liveIntervals,
        generateAtUseSite,
        parameterNames);
    allocator.visitGraph(graph);
    variableNames = allocator.names;
    shouldGroupVarDeclarations = allocator.names.numberOfVariables > 1;
  }

  void handleDelayedVariableDeclarations() {
    // If we have only one variable declaration and the first statement is an
    // assignment to that variable then we can merge the two.  We count the
    // number of variables in the variable allocator to try to avoid this issue,
    // but it sometimes happens that the variable allocator introduces a
    // temporary variable that it later eliminates.
    if (!collectedVariableDeclarations.isEmpty) {
      if (collectedVariableDeclarations.length == 1 &&
          currentContainer.statements.length >= 1 &&
          currentContainer.statements[0] is js.ExpressionStatement) {
        String name = collectedVariableDeclarations.first;
        js.ExpressionStatement statement = currentContainer.statements[0];
        if (statement.expression is js.Assignment) {
          js.Assignment assignment = statement.expression;
          if (!assignment.isCompound &&
              assignment.leftHandSide is js.VariableReference) {
            js.VariableReference variableReference = assignment.leftHandSide;
            if (variableReference.name == name) {
              js.VariableDeclaration decl = new js.VariableDeclaration(name);
              js.VariableInitialization initialization =
                  new js.VariableInitialization(decl, assignment.value);
              currentContainer.statements[0] = new js.ExpressionStatement(
                  new js.VariableDeclarationList([initialization]));
              return;
            }
          }
        }
      }
      // If we can't merge the declaration with the first assignment then we
      // just do it with a new var z,y,x; statement.
      List<js.VariableInitialization> declarations =
          <js.VariableInitialization>[];
      collectedVariableDeclarations.forEach((String name) {
        declarations.add(new js.VariableInitialization(
            new js.VariableDeclaration(name), null));
      });
      var declarationList = new js.VariableDeclarationList(declarations);
      insertStatementAtStart(new js.ExpressionStatement(declarationList));
    }
  }

  visitGraph(HGraph graph) {
    preGenerateMethod(graph);
    currentGraph = graph;
    indent++;  // We are already inside a function.
    subGraph = new SubGraph(graph.entry, graph.exit);
    HBasicBlock start = beginGraph(graph);
    visitBasicBlock(start);
    handleDelayedVariableDeclarations();
    endGraph(graph);
  }

  void visitSubGraph(SubGraph newSubGraph) {
    SubGraph oldSubGraph = subGraph;
    subGraph = newSubGraph;
    visitBasicBlock(subGraph.start);
    subGraph = oldSubGraph;
  }

  /**
   * Check whether a sub-graph can be generated as an expression, or even
   * as a declaration, or if it has to fall back to being generated as
   * a statement.
   * Expressions are anything that doesn't generate control flow constructs.
   * Declarations must only generate assignments on the form "id = expression",
   * and not, e.g., expressions where the value isn't assigned, or where it's
   * assigned to something that's not a simple variable.
   */
  int expressionType(HExpressionInformation info) {
    // The only HExpressionInformation used as part of a HBlockInformation is
    // current HSubExpressionBlockInformation, so it's the only one reaching
    // here. If we start using the other HExpressionInformation types too,
    // this code should be generalized.
    assert(info is HSubExpressionBlockInformation);
    HSubExpressionBlockInformation expressionInfo = info;
    SubGraph limits = expressionInfo.subExpression;

    // Start assuming that we can generate declarations. If we find a
    // counter-example, we degrade our assumption to either expression or
    // statement, and in the latter case, we can return immediately since
    // it can't get any worse. E.g., a function call where the return value
    // isn't used can't be in a declaration. A bailout can't be in an
    // expression.
    int result = TYPE_DECLARATION;
    HBasicBlock basicBlock = limits.start;
    do {
      HInstruction current = basicBlock.first;
      while (current != basicBlock.last) {
        // E.g, type guards.
        if (current.isControlFlow()) {
          return TYPE_STATEMENT;
        }
        // HFieldSet generates code on the form x.y = ..., which isn't
        // valid in a declaration, but it also always have no uses, so
        // it's caught by that test too.
        assert(current is! HFieldSet || current.usedBy.isEmpty);
        if (current.usedBy.isEmpty) {
          result = TYPE_EXPRESSION;
        }
        current = current.next;
      }
      if (current is HGoto) {
        basicBlock = basicBlock.successors[0];
      } else if (current is HConditionalBranch) {
        if (generateAtUseSite.contains(current)) {
          // Short-circuit control flow operator trickery.
          // Check the second half, which will continue into the join.
          // (The first half is [inputs[0]], the second half is [successors[0]],
          // and [successors[1]] is the join-block).
          basicBlock = basicBlock.successors[0];
        } else {
          // We allow an expression to end on an HIf (a condition expression).
          return identical(basicBlock, limits.end) ? result : TYPE_STATEMENT;
        }
      } else {
        // Expression-incompatible control flow.
        return TYPE_STATEMENT;
      }
    } while (limits.contains(basicBlock));
    return result;
  }

  bool isJSExpression(HExpressionInformation info) {
    return !identical(expressionType(info), TYPE_STATEMENT);
  }

  bool isJSDeclaration(HExpressionInformation info) {
    return identical(expressionType(info), TYPE_DECLARATION);
  }

  bool isJSCondition(HExpressionInformation info) {
    HSubExpressionBlockInformation graph = info;
    SubExpression limits = graph.subExpression;
    return !identical(expressionType(info), TYPE_STATEMENT) &&
       (limits.end.last is HConditionalBranch);
  }

  /**
   * Generate statements from block information.
   * If the block information contains expressions, generate only
   * assignments, and if it ends in a conditional branch, don't generate
   * the condition.
   */
  void generateStatements(HBlockInformation block) {
    if (block is HStatementInformation) {
      block.accept(this);
    } else {
      HSubExpressionBlockInformation expression = block;
      visitSubGraph(expression.subExpression);
    }
  }

  js.Block generateStatementsInNewBlock(HBlockInformation block) {
    js.Block result = new js.Block.empty();
    js.Block oldContainer = currentContainer;
    currentContainer = result;
    generateStatements(block);
    currentContainer = oldContainer;
    return result;
  }

  /**
   * If the [block] only contains one statement returns that statement. If the
   * that statement itself is a block, recursively calls this method.
   *
   * If the block is empty, returns a new instance of [js.NOP].
   */
  js.Statement unwrapStatement(js.Block block) {
    int len = block.statements.length;
    if (len == 0) return new js.EmptyStatement();
    if (len == 1) {
      js.Statement result = block.statements[0];
      if (result is Block) return unwrapStatement(result);
      return result;
    }
    return block;
  }

  /**
   * Generate expressions from block information.
   */
  js.Expression generateExpression(HExpressionInformation expression) {
    // Currently we only handle sub-expression graphs.
    assert(expression is HSubExpressionBlockInformation);

    bool oldIsGeneratingExpression = isGeneratingExpression;
    isGeneratingExpression = true;
    List<js.Expression> oldExpressionStack = expressionStack;
    List<js.Expression> sequenceElements = <js.Expression>[];
    expressionStack = sequenceElements;
    HSubExpressionBlockInformation expressionSubGraph = expression;
    visitSubGraph(expressionSubGraph.subExpression);
    expressionStack = oldExpressionStack;
    isGeneratingExpression = oldIsGeneratingExpression;
    if (sequenceElements.isEmpty) {
      // Happens when the initializer, condition or update of a loop is empty.
      return null;
    } else if (sequenceElements.length == 1) {
      return sequenceElements[0];
    } else {
      return new js.Sequence(sequenceElements);
    }
  }

  /**
    * Only visits the arguments starting at inputs[HInvoke.ARGUMENTS_OFFSET].
    */
  List<js.Expression> visitArguments(List<HInstruction> inputs) {
    assert(inputs.length >= HInvoke.ARGUMENTS_OFFSET);
    List<js.Expression> result = <js.Expression>[];
    for (int i = HInvoke.ARGUMENTS_OFFSET; i < inputs.length; i++) {
      use(inputs[i]);
      result.add(pop());
    }
    return result;
  }

  bool isVariableDeclared(String variableName) {
    return declaredLocals.contains(variableName) ||
        collectedVariableDeclarations.contains(variableName);
  }

  js.Expression generateExpressionAssignment(String variableName,
                                             js.Expression value) {
    if (value is js.Binary) {
      js.Binary binary = value;
      String op = binary.op;
      if (op == '+' || op == '-' || op == '/' || op == '*' || op == '%' ||
          op == '^' || op == '&' || op == '|') {
        if (binary.left is js.VariableUse &&
            (binary.left as js.VariableUse).name == variableName) {
          // We know now, that we can shorten x = x + y into x += y.
          // Also check for the shortcut where y equals 1: x++ and x--.
          if ((op == '+' || op == '-') &&
              binary.right is js.LiteralNumber &&
              (binary.right as js.LiteralNumber).value == "1") {
            return new js.Prefix(op == '+' ? '++' : '--', binary.left);
          }
          return new js.Assignment.compound(binary.left, op, binary.right);
        }
      }
    }
    return new js.Assignment(new js.VariableUse(variableName), value);
  }

  void assignVariable(String variableName, js.Expression value) {
    if (isGeneratingExpression) {
      // If we are in an expression then we can't declare the variable here.
      // We have no choice, but to use it and then declare it separately.
      if (!isVariableDeclared(variableName)) {
        collectedVariableDeclarations.add(variableName);
      }
      push(generateExpressionAssignment(variableName, value));
      // Otherwise if we are trying to declare inline and we are in a statement
      // then we declare (unless it was already declared).
    } else if (!shouldGroupVarDeclarations &&
               !declaredLocals.contains(variableName)) {
      // It may be necessary to remove it from the ones to be declared later.
      collectedVariableDeclarations.remove(variableName);
      declaredLocals.add(variableName);
      js.VariableDeclaration decl = new js.VariableDeclaration(variableName);
      js.VariableInitialization initialization =
          new js.VariableInitialization(decl, value);

      pushExpressionAsStatement(new js.VariableDeclarationList(
          <js.VariableInitialization>[initialization]));
    } else {
      // Otherwise we are just going to use it.  If we have not already declared
      // it then we make sure we will declare it later.
      if (!declaredLocals.contains(variableName)) {
        collectedVariableDeclarations.add(variableName);
      }
      pushExpressionAsStatement(
          generateExpressionAssignment(variableName, value));
    }
  }

  void define(HInstruction instruction) {
    // For simple type checks like i = intTypeCheck(i), we don't have to
    // emit an assignment, because the intTypeCheck just returns its
    // argument.
    bool needsAssignment = true;
    if (instruction is HTypeConversion) {
      String inputName = variableNames.getName(instruction.checkedInput);
      if (variableNames.getName(instruction) == inputName) {
        needsAssignment = false;
      }
    }

    if (needsAssignment &&
        !instruction.isControlFlow() && variableNames.hasName(instruction)) {
      visitExpression(instruction);
      assignVariable(variableNames.getName(instruction), pop());
      return;
    }

    if (isGeneratingExpression) {
      visitExpression(instruction);
    } else {
      visitStatement(instruction);
    }
  }

  void use(HInstruction argument) {
    if (isGenerateAtUseSite(argument)) {
      visitExpression(argument);
    } else if (argument is HCheck && argument.isControlFlow()) {
      // A [HCheck] that has control flow can never be used as an
      // expression and may not have a name. Therefore we just use the
      // checked instruction.
      HCheck check = argument;
      use(check.checkedInput);
    } else {
      push(new js.VariableUse(variableNames.getName(argument)));
    }
  }

  visit(HInstruction node) {
    node.accept(this);
  }

  visitExpression(HInstruction node) {
    bool oldIsGeneratingExpression = isGeneratingExpression;
    isGeneratingExpression = true;
    visit(node);
    isGeneratingExpression = oldIsGeneratingExpression;
  }

  visitStatement(HInstruction node) {
    assert(!isGeneratingExpression);
    visit(node);
    if (!expressionStack.isEmpty) {
      assert(expressionStack.length == 1);
      pushExpressionAsStatement(pop());
    }
  }

  void continueAsBreak(LabelElement target) {
    pushStatement(new js.Break(backend.namer.continueLabelName(target)));
  }

  void implicitContinueAsBreak(TargetElement target) {
    pushStatement(new js.Break(
        backend.namer.implicitContinueLabelName(target)));
  }

  void implicitBreakWithLabel(TargetElement target) {
    pushStatement(new js.Break(backend.namer.implicitBreakLabelName(target)));
  }

  js.Statement wrapIntoLabels(js.Statement result, List<LabelElement> labels) {
    for (LabelElement label in labels) {
      if (label.isTarget) {
        String breakLabelString = backend.namer.breakLabelName(label);
        result = new js.LabeledStatement(breakLabelString, result);
      }
    }
    return result;
  }


  // The regular [visitIf] method implements the needed logic.
  bool visitIfInfo(HIfBlockInformation info) => false;

  bool visitSwitchInfo(HSwitchBlockInformation info) {
    bool isExpression = isJSExpression(info.expression);
    if (!isExpression) {
      generateStatements(info.expression);
    }

    if (isExpression) {
      push(generateExpression(info.expression));
    } else {
      use(info.expression.conditionExpression);
    }
    js.Expression key = pop();
    List<js.SwitchClause> cases = <js.SwitchClause>[];

    js.Block oldContainer = currentContainer;
    for (int i = 0; i < info.matchExpressions.length; i++) {
      for (Constant constant in info.matchExpressions[i]) {
        generateConstant(constant);
        currentContainer = new js.Block.empty();
        cases.add(new js.Case(pop(), currentContainer));
      }
      if (i == info.matchExpressions.length - 1 && info.hasDefault) {
        currentContainer = new js.Block.empty();
        cases.add(new js.Default(currentContainer));
      }
      generateStatements(info.statements[i]);
    }
    currentContainer = oldContainer;

    js.Statement result = new js.Switch(key, cases);
    pushStatement(wrapIntoLabels(result, info.labels));
    return true;
  }

  bool visitSequenceInfo(HStatementSequenceInformation info) {
    return false;
  }

  bool visitSubGraphInfo(HSubGraphBlockInformation info) {
    visitSubGraph(info.subGraph);
    return true;
  }

  bool visitSubExpressionInfo(HSubExpressionBlockInformation info) {
    return false;
  }

  bool visitAndOrInfo(HAndOrBlockInformation info) {
    return false;
  }

  bool visitTryInfo(HTryBlockInformation info) {
    js.Block body = generateStatementsInNewBlock(info.body);
    js.Catch catchPart = null;
    js.Block finallyPart = null;
    if (info.catchBlock != null) {
      HParameterValue exception = info.catchVariable;
      String name = variableNames.getName(exception);
      parameterNames[exception.sourceElement] = name;
      js.VariableDeclaration decl = new js.VariableDeclaration(name);
      js.Block catchBlock = generateStatementsInNewBlock(info.catchBlock);
      catchPart = new js.Catch(decl, catchBlock);
    }
    if (info.finallyBlock != null) {
      finallyPart = generateStatementsInNewBlock(info.finallyBlock);
    }
    pushStatement(new js.Try(body, catchPart, finallyPart));
    return true;
  }

  void visitBodyIgnoreLabels(HLoopBlockInformation info) {
    if (info.body.start.isLabeledBlock()) {
      HBlockInformation oldInfo = currentBlockInformation;
      currentBlockInformation = info.body.start.blockFlow.body;
      generateStatements(info.body);
      currentBlockInformation = oldInfo;
    } else {
      generateStatements(info.body);
    }
  }

  bool visitLoopInfo(HLoopBlockInformation info) {
    HExpressionInformation condition = info.condition;
    bool isConditionExpression = isJSCondition(condition);

    js.Loop loop;

    switch (info.kind) {
      // Treate all three "test-first" loops the same way.
      case HLoopBlockInformation.FOR_LOOP:
      case HLoopBlockInformation.WHILE_LOOP:
      case HLoopBlockInformation.FOR_IN_LOOP:
        HBlockInformation initialization = info.initializer;
        int initializationType = TYPE_STATEMENT;
        if (initialization != null) {
          initializationType = expressionType(initialization);
          if (initializationType == TYPE_STATEMENT) {
            generateStatements(initialization);
            initialization = null;
          }
        }
        if (isConditionExpression &&
            info.updates != null && isJSExpression(info.updates)) {
          // If we have an updates graph, and it's expressible as an
          // expression, generate a for-loop.
          js.Expression jsInitialization = null;
          if (initialization != null) {
            int delayedVariablesCount = collectedVariableDeclarations.length;
            jsInitialization = generateExpression(initialization);
            if (!shouldGroupVarDeclarations &&
                delayedVariablesCount < collectedVariableDeclarations.length) {
              // We just added a new delayed variable-declaration. See if we
              // can put in a 'var' in front of the initialization to make it
              // go away.
              List<js.Expression> expressions;
              if (jsInitialization is js.Sequence) {
                expressions = jsInitialization.expressions;
              } else {
                expressions = <js.Expression>[jsInitialization];
              }
              bool canTransformToVariableDeclaration = true;
              for (js.Expression expression in expressions) {
                bool expressionIsVariableAssignment = false;
                if (expression is js.Assignment) {
                  js.Assignment assignment = expression;
                  if (assignment.leftHandSide is js.VariableUse &&
                      assignment.compoundTarget == null) {
                    expressionIsVariableAssignment = true;
                  }
                }
                if (!expressionIsVariableAssignment) {
                  canTransformToVariableDeclaration = false;
                  break;
                }
              }
              if (canTransformToVariableDeclaration) {
                List<js.VariableInitialization> inits =
                    <js.VariableInitialization>[];
                for (js.Assignment assignment in expressions) {
                  String id = (assignment.leftHandSide as js.VariableUse).name;
                  js.Node declaration = new js.VariableDeclaration(id);
                  inits.add(new js.VariableInitialization(declaration,
                                                          assignment.value));
                  collectedVariableDeclarations.remove(id);
                }
                jsInitialization = new js.VariableDeclarationList(inits);
              }
            }
          }
          js.Expression jsCondition = generateExpression(condition);
          js.Expression jsUpdates = generateExpression(info.updates);
          // The body might be labeled. Ignore this when recursing on the
          // subgraph.
          // TODO(lrn): Remove this extra labeling when handling all loops
          // using subgraphs.
          js.Block oldContainer = currentContainer;
          js.Statement body = new js.Block.empty();
          currentContainer = body;
          visitBodyIgnoreLabels(info);
          currentContainer = oldContainer;
          body = unwrapStatement(body);
          loop = new js.For(jsInitialization, jsCondition, jsUpdates, body);
        } else {
          // We have either no update graph, or it's too complex to
          // put in an expression.
          if (initialization != null) {
            generateStatements(initialization);
          }
          js.Expression jsCondition;
          js.Block oldContainer = currentContainer;
          js.Statement body = new js.Block.empty();
          if (isConditionExpression) {
            jsCondition = generateExpression(condition);
            currentContainer = body;
          } else {
            jsCondition = newLiteralBool(true);
            currentContainer = body;
            generateStatements(condition);
            use(condition.conditionExpression);
            js.Expression ifTest = new js.Prefix("!", pop());
            js.Break jsBreak = new js.Break(null);
            pushStatement(new js.If.noElse(ifTest, jsBreak));
          }
          if (info.updates != null) {
            wrapLoopBodyForContinue(info);
            generateStatements(info.updates);
          } else {
            visitBodyIgnoreLabels(info);
          }
          currentContainer = oldContainer;
          body = unwrapStatement(body);
          loop = new js.While(jsCondition, body);
        }
        break;
      case HLoopBlockInformation.DO_WHILE_LOOP:
        // Generate do-while loop in all cases.
        if (info.initializer != null) {
          generateStatements(info.initializer);
        }
        js.Block oldContainer = currentContainer;
        js.Statement body = new js.Block.empty();
        currentContainer = body;
        if (!isConditionExpression || info.updates != null) {
          wrapLoopBodyForContinue(info);
        } else {
          visitBodyIgnoreLabels(info);
        }
        if (info.updates != null) {
          generateStatements(info.updates);
        }
        if (isConditionExpression) {
          push(generateExpression(condition));
        } else {
          generateStatements(condition);
          use(condition.conditionExpression);
        }
        js.Expression jsCondition = pop();
        currentContainer = oldContainer;
        body = unwrapStatement(body);
        loop = new js.Do(body, jsCondition);
        break;
      default:
        compiler.internalError(
          'Unexpected loop kind: ${info.kind}',
          instruction: condition.conditionExpression);
    }
    attachLocationRange(loop, info.sourcePosition, info.endSourcePosition);
    pushStatement(wrapIntoLabels(loop, info.labels));
    return true;
  }

  bool visitLabeledBlockInfo(HLabeledBlockInformation labeledBlockInfo) {
    preLabeledBlock(labeledBlockInfo);
    Link<Element> continueOverrides = const Link<Element>();

    js.Block oldContainer = currentContainer;
    js.Block body = new js.Block.empty();
    js.Statement result = body;

    currentContainer = body;

    // If [labeledBlockInfo.isContinue], the block is an artificial
    // block around the body of a loop with an update block, so that
    // continues of the loop can be written as breaks of the body
    // block.
    if (labeledBlockInfo.isContinue) {
      for (LabelElement label in labeledBlockInfo.labels) {
        if (label.isContinueTarget) {
          String labelName = backend.namer.continueLabelName(label);
          result = new js.LabeledStatement(labelName, result);
          continueAction[label] = continueAsBreak;
          continueOverrides = continueOverrides.prepend(label);
        }
      }
      // For handling unlabeled continues from the body of a loop.
      // TODO(lrn): Consider recording whether the target is in fact
      // a target of an unlabeled continue, and not generate this if it isn't.
      TargetElement target = labeledBlockInfo.target;
      String labelName = backend.namer.implicitContinueLabelName(target);
      result = new js.LabeledStatement(labelName, result);
      continueAction[target] = implicitContinueAsBreak;
      continueOverrides = continueOverrides.prepend(target);
    } else {
      for (LabelElement label in labeledBlockInfo.labels) {
        if (label.isBreakTarget) {
          String labelName = backend.namer.breakLabelName(label);
          result = new js.LabeledStatement(labelName, result);
        }
      }
      TargetElement target = labeledBlockInfo.target;
      if (target.isSwitch) {
        // This is an extra block around a switch that is generated
        // as a nested if/else chain. We add an extra break target
        // so that case code can break.
        String labelName = backend.namer.implicitBreakLabelName(target);
        result = new js.LabeledStatement(labelName, result);
        breakAction[target] = implicitBreakWithLabel;
      }
    }

    currentContainer = body;
    startLabeledBlock(labeledBlockInfo);
    generateStatements(labeledBlockInfo.body);
    endLabeledBlock(labeledBlockInfo);

    if (labeledBlockInfo.isContinue) {
      while (!continueOverrides.isEmpty) {
        continueAction.remove(continueOverrides.head);
        continueOverrides = continueOverrides.tail;
      }
    } else {
      breakAction.remove(labeledBlockInfo.target);
    }

    currentContainer = oldContainer;
    pushStatement(result);
    return true;
  }

  // Wraps a loop body in a block to make continues have a target to break
  // to (if necessary).
  void wrapLoopBodyForContinue(HLoopBlockInformation info) {
    TargetElement target = info.target;
    if (target != null && target.isContinueTarget) {
      js.Block oldContainer = currentContainer;
      js.Block body = new js.Block.empty();
      currentContainer = body;
      js.Statement result = body;
      for (LabelElement label in info.labels) {
        if (label.isContinueTarget) {
          String labelName = backend.namer.continueLabelName(label);
          result = new js.LabeledStatement(labelName, result);
          continueAction[label] = continueAsBreak;
        }
      }
      String labelName = backend.namer.implicitContinueLabelName(target);
      result = new js.LabeledStatement(labelName, result);
      continueAction[info.target] = implicitContinueAsBreak;
      visitBodyIgnoreLabels(info);
      continueAction.remove(info.target);
      for (LabelElement label in info.labels) {
        if (label.isContinueTarget) {
          continueAction.remove(label);
        }
      }
      currentContainer = oldContainer;
      pushStatement(result);
    } else {
      // Loop body contains no continues, so we don't need a break target.
      generateStatements(info.body);
    }
  }

  bool handleBlockFlow(HBlockFlow block) {
    HBlockInformation info = block.body;
    // If we reach here again while handling the attached information,
    // e.g., because we call visitSubGraph on a subgraph starting on
    // the same block, don't handle it again.
    // When the structure graph is complete, we will be able to have
    // different structures starting on the same basic block (e.g., an
    // "if" and its condition).
    if (identical(info, currentBlockInformation)) return false;

    HBlockInformation oldBlockInformation = currentBlockInformation;
    currentBlockInformation = info;
    bool success = info.accept(this);
    currentBlockInformation = oldBlockInformation;
    if (success) {
      HBasicBlock continuation = block.continuation;
      if (continuation != null) {
        visitBasicBlock(continuation);
      }
    }
    return success;
  }

  void visitBasicBlock(HBasicBlock node) {
    // Abort traversal if we are leaving the currently active sub-graph.
    if (!subGraph.contains(node)) return;

    currentBlock = node;
    // If this node has block-structure based information attached,
    // try using that to traverse from here.
    if (node.blockFlow != null &&
        handleBlockFlow(node.blockFlow)) {
      return;
    }
    // Flow based traversal.
    if (node.isLoopHeader() &&
        !identical(node.loopInformation.loopBlockInformation, currentBlockInformation)) {
      beginLoop(node);
    }
    iterateBasicBlock(node);
  }

  void emitAssignment(String destination, String source) {
    assignVariable(destination, new js.VariableUse(source));
  }

  /**
   * Sequentialize a list of conceptually parallel copies. Parallel
   * copies may contain cycles, that this method breaks.
   */
  void sequentializeCopies(List<Copy> copies,
                           String tempName,
                           void doAssignment(String target, String source)) {
    // Map to keep track of the current location (ie the variable that
    // holds the initial value) of a variable.
    Map<String, String> currentLocation = new Map<String, String>();

    // Map to keep track of the initial value of a variable.
    Map<String, String> initialValue = new Map<String, String>();

    // List of variables to assign a value.
    List<String> worklist = <String>[];

    // List of variables that we can assign a value to (ie are not
    // being used anymore).
    List<String> ready = <String>[];

    // Prune [copies] by removing self-copies.
    List<Copy> prunedCopies = <Copy>[];
    for (Copy copy in copies) {
      if (copy.source != copy.destination) {
        prunedCopies.add(copy);
      }
    }
    copies = prunedCopies;


    // For each copy, set the current location of the source to
    // itself, and the initial value of the destination to the source.
    // Add the destination to the list of copies to make.
    for (Copy copy in copies) {
      currentLocation[copy.source] = copy.source;
      initialValue[copy.destination] = copy.source;
      worklist.add(copy.destination);
    }

    // For each copy, if the destination does not have a current
    // location, then we can safely assign to it.
    for (Copy copy in copies) {
      if (currentLocation[copy.destination] == null) {
        ready.add(copy.destination);
      }
    }

    while (!worklist.isEmpty) {
      while (!ready.isEmpty) {
        String destination = ready.removeLast();
        String source = initialValue[destination];
        // Since [source] might have been updated, use the current
        // location of [source]
        String copy = currentLocation[source];
        doAssignment(destination, copy);
        // Now [destination] is the current location of [source].
        currentLocation[source] = destination;
        // If [source] hasn't been updated and needs to have a value,
        // add it to the list of variables that can be updated. Copies
        // of [source] will now use [destination].
        if (source == copy && initialValue[source] != null) {
          ready.add(source);
        }
      }

      // Check if we have a cycle.
      String current = worklist.removeLast();
      // If [current] is used as a source, and the assignment has been
      // done, we are done with this variable. Otherwise there is a
      // cycle that we break by using a temporary name.
      if (currentLocation[current] != null
          && current != currentLocation[initialValue[current]]) {
        doAssignment(tempName, current);
        currentLocation[current] = tempName;
        // [current] can now be safely updated. Copies of [current]
        // will now use [tempName].
        ready.add(current);
      }
    }
  }

  void assignPhisOfSuccessors(HBasicBlock node) {
    CopyHandler handler = variableNames.getCopyHandler(node);
    if (handler == null) return;

    // Map the instructions to strings.
    List<Copy> copies = handler.copies.map((Copy copy) {
      return new Copy(variableNames.getName(copy.source),
                      variableNames.getName(copy.destination));
    });

    sequentializeCopies(copies, variableNames.getSwapTemp(), emitAssignment);

    for (Copy copy in handler.assignments) {
      String name = variableNames.getName(copy.destination);
      use(copy.source);
      assignVariable(name, pop());
    }
  }

  void iterateBasicBlock(HBasicBlock node) {
    HInstruction instruction = node.first;
    while (!identical(instruction, node.last)) {
      if (instruction is HTypeGuard || instruction is HBailoutTarget) {
        visit(instruction);
      } else if (!isGenerateAtUseSite(instruction)) {
        define(instruction);
      }
      instruction = instruction.next;
    }
    assignPhisOfSuccessors(node);
    visit(instruction);
  }

  visitInvokeBinary(HInvokeBinary node, String op) {
    if (node.isBuiltin(types)) {
      use(node.left);
      js.Expression jsLeft = pop();
      use(node.right);
      push(new js.Binary(op, jsLeft, pop()), node);
    } else {
      visitInvokeStatic(node);
    }
  }

  // We want the outcome of bit-operations to be positive. We use the unsigned
  // shift operator to achieve this.
  visitBitInvokeBinary(HBinaryBitOp node, String op) {
    visitInvokeBinary(node, op);
    if (node.isBuiltin(types) && requiresUintConversion(node)) {
      push(new js.Binary(">>>", pop(), new js.LiteralNumber("0")), node);
    }
  }

  visitInvokeUnary(HInvokeUnary node, String op) {
    if (node.isBuiltin(types)) {
      use(node.operand);
      push(new js.Prefix(op, pop()), node);
    } else {
      visitInvokeStatic(node);
    }
  }

  // We want the outcome of bit-operations to be positive. We use the unsigned
  // shift operator to achieve this.
  visitBitInvokeUnary(HInvokeUnary node, String op) {
    visitInvokeUnary(node, op);
    if (node.isBuiltin(types) && requiresUintConversion(node)) {
      push(new js.Binary(">>>", pop(), new js.LiteralNumber("0")), node);
    }
  }

  void emitIdentityComparison(HInstruction left, HInstruction right) {
    String op = singleIdentityComparison(left, right, types);
    if (op != null) {
      use(left);
      js.Expression jsLeft = pop();
      use(right);
      push(new js.Binary(op, jsLeft, pop()));
    } else {
      assert(NullConstant.JsNull == 'null');
      use(left);
      js.Binary leftEqualsNull =
          new js.Binary("==", pop(), new js.LiteralNull());
      use(right);
      js.Binary rightEqualsNull =
          new js.Binary("==", pop(), new js.LiteralNull());
      use(right);
      use(left);
      js.Binary tripleEq = new js.Binary("===", pop(), pop());

      push(new js.Conditional(leftEqualsNull, rightEqualsNull, tripleEq));
    }
  }

  visitEquals(HEquals node) {
    if (node.isBuiltin(types)) {
      emitIdentityComparison(node.left, node.right);
    } else {
      visitInvokeStatic(node);
    }
  }

  visitIdentity(HIdentity node) {
    assert(node.isBuiltin(types));
    emitIdentityComparison(node.left, node.right);
  }

  visitAdd(HAdd node)               => visitInvokeBinary(node, '+');
  visitDivide(HDivide node)         => visitInvokeBinary(node, '/');
  visitMultiply(HMultiply node)     => visitInvokeBinary(node, '*');
  visitSubtract(HSubtract node)     => visitInvokeBinary(node, '-');
  // Truncating divide does not have a JS equivalent.
  visitTruncatingDivide(HTruncatingDivide node) => visitInvokeStatic(node);
  // Modulo cannot be mapped to the native operator (different semantics).
  visitModulo(HModulo node)                     => visitInvokeStatic(node);

  visitBitAnd(HBitAnd node)         => visitBitInvokeBinary(node, '&');
  visitBitNot(HBitNot node)         => visitBitInvokeUnary(node, '~');
  visitBitOr(HBitOr node)           => visitBitInvokeBinary(node, '|');
  visitBitXor(HBitXor node)         => visitBitInvokeBinary(node, '^');
  visitShiftRight(HShiftRight node) => visitBitInvokeBinary(node, '>>');
  visitShiftLeft(HShiftLeft node)   => visitBitInvokeBinary(node, '<<');

  visitNegate(HNegate node)         => visitInvokeUnary(node, '-');

  visitLess(HLess node)                 => visitInvokeBinary(node, '<');
  visitLessEqual(HLessEqual node)       => visitInvokeBinary(node, '<=');
  visitGreater(HGreater node)           => visitInvokeBinary(node, '>');
  visitGreaterEqual(HGreaterEqual node) => visitInvokeBinary(node, '>=');

  visitBoolify(HBoolify node) {
    assert(node.inputs.length == 1);
    use(node.inputs[0]);
    push(new js.Binary('===', pop(), newLiteralBool(true)), node);
  }

  visitExit(HExit node) {
    // Don't do anything.
  }

  visitGoto(HGoto node) {
    assert(currentBlock.successors.length == 1);
    List<HBasicBlock> dominated = currentBlock.dominatedBlocks;
    // With the exception of the entry-node which dominates its successor
    // and the exit node, no block finishing with a 'goto' can have more than
    // one dominated block (since it has only one successor).
    // If the successor is dominated by another block, then the other block
    // is responsible for visiting the successor.
    if (dominated.isEmpty) return;
    if (dominated.length > 2) {
      compiler.internalError('dominated.length = ${dominated.length}',
                             instruction: node);
    }
    if (dominated.length == 2 && !identical(currentBlock, currentGraph.entry)) {
      compiler.internalError('currentBlock !== currentGraph.entry',
                             instruction: node);
    }
    assert(dominated[0] == currentBlock.successors[0]);
    visitBasicBlock(dominated[0]);
  }

  /**
   * Checks if [map] contains an [ElementAction] for [element], and
   * if so calls that action and returns true.
   * Otherwise returns false.
   */
  bool tryCallAction(Map<Element, ElementAction> map, Element element) {
    ElementAction action = map[element];
    if (action == null) return false;
    action(element);
    return true;
  }

  visitBreak(HBreak node) {
    assert(currentBlock.successors.length == 1);
    if (node.label != null) {
      LabelElement label = node.label;
      if (!tryCallAction(breakAction, label)) {
        pushStatement(new js.Break(backend.namer.breakLabelName(label)), node);
      }
    } else {
      TargetElement target = node.target;
      if (!tryCallAction(breakAction, target)) {
        pushStatement(new js.Break(null), node);
      }
    }
  }

  visitContinue(HContinue node) {
    assert(currentBlock.successors.length == 1);
    if (node.label != null) {
      LabelElement label = node.label;
      if (!tryCallAction(continueAction, label)) {
        // TODO(floitsch): should this really be the breakLabelName?
        pushStatement(new js.Continue(backend.namer.breakLabelName(label)),
                      node);
      }
    } else {
      TargetElement target = node.target;
      if (!tryCallAction(continueAction, target)) {
        pushStatement(new js.Continue(null), node);
      }
    }
  }

  visitExitTry(HExitTry node) {
    // An [HExitTry] is used to represent the control flow graph of a
    // try/catch block, ie the try body is always a predecessor
    // of the catch and finally. Here, we continue visiting the try
    // body by visiting the block that contains the user-level control
    // flow instruction.
    visitBasicBlock(node.bodyTrySuccessor);
  }

  visitTry(HTry node) {
    // We should never get here. Try/catch/finally is always handled using block
    // information in [visitTryInfo], or not at all, in the case of the bailout
    // generator.
    compiler.internalError('visitTry should not be called', instruction: node);
  }

  bool tryControlFlowOperation(HIf node) {
    if (!controlFlowOperators.contains(node)) return false;
    HPhi phi = node.joinBlock.phis.first;
    bool atUseSite = isGenerateAtUseSite(phi);
    // Don't generate a conditional operator in this situation:
    // i = condition ? bar() : i;
    // But generate this instead:
    // if (condition) i = bar();
    // Usually, the variable name is longer than 'if' and it takes up
    // more space to duplicate the name.
    if (!atUseSite
        && variableNames.getName(phi) == variableNames.getName(phi.inputs[1])) {
      return false;
    }
    if (!atUseSite) define(phi);
    visitBasicBlock(node.joinBlock);
    return true;
  }

  void generateIf(HIf node, HIfBlockInformation info) {
    use(node.inputs[0]);
    js.Expression test = pop();

    HStatementInformation thenGraph = info.thenGraph;
    HStatementInformation elseGraph = info.elseGraph;
    js.Statement thenPart =
        unwrapStatement(generateStatementsInNewBlock(thenGraph));
    js.Statement elsePart =
        unwrapStatement(generateStatementsInNewBlock(elseGraph));

    pushStatement(new js.If(test, thenPart, elsePart), node);
  }

  visitIf(HIf node) {
    if (tryControlFlowOperation(node)) return;

    HInstruction condition = node.inputs[0];
    HIfBlockInformation info = node.blockInformation.body;

    if (condition.isConstant()) {
      HConstant constant = condition;
      if (constant.constant.isTrue()) {
        generateStatements(info.thenGraph);
      } else {
        generateStatements(info.elseGraph);
      }
    } else {
      generateIf(node, info);
    }

    HBasicBlock joinBlock = node.joinBlock;
    if (joinBlock != null && !identical(joinBlock.dominator, node.block)) {
      // The join block is dominated by a block in one of the branches.
      // The subgraph traversal never reached it, so we visit it here
      // instead.
      visitBasicBlock(joinBlock);
    }

    // Visit all the dominated blocks that are not part of the then or else
    // branches, and is not the join block.
    // Depending on how the then/else branches terminate
    // (e.g., return/throw/break) there can be any number of these.
    List<HBasicBlock> dominated = node.block.dominatedBlocks;
    for (int i = 2; i < dominated.length; i++) {
      visitBasicBlock(dominated[i]);
    }
  }

  js.Call jsPropertyCall(js.Expression receiver,
                         String fieldName,
                         List<js.Expression> arguments) {
    return new js.Call(new js.PropertyAccess.field(receiver, fieldName),
                       arguments);
  }

  visitInvokeDynamicMethod(HInvokeDynamicMethod node) {
    use(node.receiver);
    js.Expression object = pop();
    SourceString name = node.selector.name;
    String methodName;
    List<js.Expression> arguments;
    Element target = node.element;

    // Avoid adding the generative constructor name to the list of
    // seen selectors.
    if (target != null && target.isGenerativeConstructorBody()) {
      methodName = name.slowToString();
      arguments = visitArguments(node.inputs);
    } else {
      methodName = backend.namer.instanceMethodInvocationName(
          node.selector.library, name, node.selector);
      arguments = visitArguments(node.inputs);
      bool inLoop = node.block.enclosingLoopHeader != null;

      // Register this invocation to collect the types used at all call sites.
      Selector selector = getOptimizedSelectorFor(node, node.selector);
      backend.registerDynamicInvocation(node, selector, types);

      // If we don't know what we're calling or if we are calling a getter,
      // we need to register that fact that we may be calling a closure
      // with the same arguments.
      if (target == null || target.isGetter()) {
        // TODO(kasperl): If we have a typed selector for the call, we
        // may know something about the types of closures that need
        // the specific closure call method.
        Selector call = new Selector.callClosureFrom(selector);
        world.registerDynamicInvocation(call.name, call);
      }

      if (target != null) {
        // If we know we're calling a specific method, register that
        // method only.
        if (inLoop) backend.builder.functionsCalledInLoop.add(target);
        world.registerDynamicInvocationOf(target);
      } else {
        if (inLoop) backend.builder.selectorsCalledInLoop[name] = selector;
        world.registerDynamicInvocation(name, selector);
      }
    }
    push(jsPropertyCall(object, methodName, arguments), node);
  }

  Selector getOptimizedSelectorFor(HInvokeDynamic node,
                                   Selector defaultSelector) {
    // TODO(4434): For private members we need to use the untyped selector.
    if (defaultSelector.name.isPrivate()) return defaultSelector;
    // If [JSInvocationMirror.invokeOn] has been called, we must not create a
    // typed selector based on the receiver type.
    if (node.element == null && // Invocation is not exact.
        backend.compiler.enabledInvokeOn) {
      return defaultSelector;
    }
    HType receiverHType = types[node.inputs[0]];
    DartType receiverType = receiverHType.computeType(compiler);
    if (receiverType != null) {
      return new TypedSelector(receiverType, defaultSelector);
    } else {
      return defaultSelector;
    }
  }

  visitInvokeDynamicSetter(HInvokeDynamicSetter node) {
    use(node.receiver);
    Selector setter = node.selector;
    String name = backend.namer.setterName(setter.library, setter.name);
    push(jsPropertyCall(pop(), name, visitArguments(node.inputs)), node);
    Selector selector = getOptimizedSelectorFor(node, setter);
    world.registerDynamicSetter(setter.name, selector);
    backend.addedDynamicSetter(selector, types[node.inputs[1]]);
  }

  visitInvokeDynamicGetter(HInvokeDynamicGetter node) {
    use(node.receiver);
    Selector getter = node.selector;
    String name = backend.namer.getterName(getter.library, getter.name);
    push(jsPropertyCall(pop(), name, visitArguments(node.inputs)), node);
    world.registerDynamicGetter(
        getter.name, getOptimizedSelectorFor(node, getter));
  }

  visitInvokeClosure(HInvokeClosure node) {
    use(node.receiver);
    push(jsPropertyCall(pop(),
                        backend.namer.closureInvocationName(node.selector),
                        visitArguments(node.inputs)),
         node);
    Selector call = new Selector.callClosureFrom(node.selector);
    world.registerDynamicInvocation(call.name, call);
    // A closure can also be invoked through [HInvokeDynamicMethod] by
    // explicitly calling the [:call:] method. Therefore, we must also
    // register types here to let the backend invalidate wrong
    // optimizations.
    backend.registerDynamicInvocation(node, call, types);
  }

  visitInvokeStatic(HInvokeStatic node) {
    if (true &&
        (node.typeCode() == HInstruction.INVOKE_STATIC_TYPECODE ||
         node.typeCode() == HInstruction.INVOKE_INTERCEPTOR_TYPECODE)) {
      // Register this invocation to collect the types used at all call sites.
      backend.registerStaticInvocation(node, types);
    }
    use(node.target);
    push(new js.Call(pop(), visitArguments(node.inputs)), node);
  }

  visitInvokeSuper(HInvokeSuper node) {
    Element superMethod = node.element;
    Element superClass = superMethod.getEnclosingClass();
    if (superMethod.kind == ElementKind.FIELD) {
      ClassElement currentClass = work.element.getEnclosingClass();
      if (currentClass.isClosure()) {
        ClosureClassElement closure = currentClass;
        currentClass = closure.methodElement.getEnclosingClass();
      }
      String fieldName;
      if (currentClass.isShadowedByField(superMethod)) {
        fieldName = backend.namer.shadowedFieldName(superMethod);
      } else {
        LibraryElement library = superMethod.getLibrary();
        SourceString name = superMethod.name;
        fieldName = backend.namer.instanceFieldName(library, name);
      }
      use(node.inputs[1]);
      js.PropertyAccess access =
          new js.PropertyAccess.field(pop(), fieldName);
      if (node.isSetter) {
        use(node.value);
        push(new js.Assignment(access, pop()), node);
      } else {
        push(access, node);
      }
    } else {
      String methodName;
      if (superMethod.kind == ElementKind.FUNCTION ||
          superMethod.kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
        methodName = backend.namer.instanceMethodName(superMethod);
      } else if (superMethod.kind == ElementKind.GETTER) {
        methodName =
            backend.namer.getterName(currentLibrary, superMethod.name);
      } else {
        assert(superMethod.kind == ElementKind.SETTER);
        methodName =
            backend.namer.setterName(currentLibrary, superMethod.name);
      }
      String className = backend.namer.isolateAccess(superClass);
      js.VariableUse classReference = new js.VariableUse(className);
      js.PropertyAccess prototype =
          new js.PropertyAccess.field(classReference, "prototype");
      js.PropertyAccess method =
          new js.PropertyAccess.field(prototype, methodName);
      push(jsPropertyCall(method, "call", visitArguments(node.inputs)), node);
    }
    world.registerStaticUse(superMethod);
  }

  visitFieldGet(HFieldGet node) {
    String name = backend.namer.getName(node.element);
    use(node.receiver);
    push(new js.PropertyAccess.field(pop(), name), node);
    HType receiverHType = types[node.receiver];
    DartType type = receiverHType.computeType(compiler);
    if (type != null) {
      world.registerFieldGetter(
          node.element.name, node.element.getLibrary(), type);
    }
  }

  // Determine if an instruction is a simple number computation
  // involving only things with guaranteed number types and a given
  // field.
  bool isSimpleFieldNumberComputation(HInstruction value, HFieldSet node) {
    if (value.guaranteedType.union(HType.NUMBER, compiler) == HType.NUMBER) {
      return true;
    }
    if (value is HBinaryArithmetic) {
      return (isSimpleFieldNumberComputation(value.left, node) &&
              isSimpleFieldNumberComputation(value.right, node));
    }
    if (value is HFieldGet) return value.element == node.element;
    return false;
  }

  visitFieldSet(HFieldSet node) {
    String name = backend.namer.getName(node.element);
    DartType type = types[node.receiver].computeType(compiler);
    if (type != null) {
      // Field setters in the generative constructor body are handled in a
      // step "SsaConstructionFieldTypes" in the ssa optimizer.
      if (!work.element.isGenerativeConstructorBody()) {
        world.registerFieldSetter(
            node.element.name, node.element.getLibrary(), type);
        backend.registerFieldSetter(
            work.element, node.element, types[node.value]);
      }
    }
    use(node.receiver);
    js.Expression receiver = pop();
    use(node.value);
    push(new js.Assignment(new js.PropertyAccess.field(receiver, name), pop()),
         node);
  }

  visitLocalGet(HLocalGet node) {
    use(node.receiver);
  }

  visitLocalSet(HLocalSet node) {
    use(node.value);
    assignVariable(variableNames.getName(node.receiver), pop());
  }

  visitForeign(HForeign node) {
    visitedForeignCode = true;
    String code = node.code.slowToString();
    List<HInstruction> inputs = node.inputs;
    if (node.isJsStatement(types)) {
      if (!inputs.isEmpty) {
        compiler.internalError("foreign statement with inputs: $code",
                               instruction: node);
      }
      pushStatement(new js.LiteralStatement(code), node);
    } else {
      List<js.Expression> data = <js.Expression>[];
      for (int i = 0; i < inputs.length; i++) {
        use(inputs[i]);
        data.add(pop());
      }
      push(new js.LiteralExpression.withData(code, data), node);
    }
  }

  visitForeignNew(HForeignNew node) {
    visitedForeignCode = true;
    String jsClassReference = backend.namer.isolateAccess(node.element);
    List<HInstruction> inputs = node.inputs;
    // We can't use 'visitArguments', since our arguments start at input[0].
    List<js.Expression> arguments = <js.Expression>[];
    for (int i = 0; i < inputs.length; i++) {
      use(inputs[i]);
      arguments.add(pop());
    }
    // TODO(floitsch): jsClassReference is an Access. We shouldn't treat it
    // as if it was a string.
    push(new js.New(new js.VariableUse(jsClassReference), arguments), node);
  }

  js.Expression newLiteralBool(bool value) {
    if (compiler.enableMinification) {
      // Use !0 for true, !1 for false.
      return new js.Prefix("!", new js.LiteralNumber(value ? "0" : "1"));
    } else {
      return new js.LiteralBool(value);
    }
  }

  void generateConstant(Constant constant) {
    Namer namer = backend.namer;
    // TODO(floitsch): should we use the ConstantVisitor here?
    if (!constant.isObject()) {
      if (constant.isBool()) {
        BoolConstant boolConstant = constant;
        push(newLiteralBool(boolConstant.value));
      } else if (constant.isNum()) {
        // TODO(floitsch): get rid of the code buffer.
        CodeBuffer buffer = new CodeBuffer();
        backend.emitter.writeConstantToBuffer(constant, buffer);
        push(new js.LiteralNumber(buffer.toString()));
      } else if (constant.isNull()) {
        push(new js.LiteralNull());
      } else if (constant.isString()) {
        // TODO(floitsch): get rid of the code buffer.
        CodeBuffer buffer = new CodeBuffer();
        backend.emitter.writeConstantToBuffer(constant, buffer);
        push(new js.LiteralString(buffer.toString()));
      } else if (constant.isFunction()) {
        FunctionConstant function = constant;
        world.registerStaticUse(function.element);
        push(new js.VariableUse(namer.isolateAccess(function.element)));
      } else if (constant.isSentinel()) {
        // TODO(floitsch): get rid of the code buffer.
        CodeBuffer buffer = new CodeBuffer();
        backend.emitter.writeConstantToBuffer(constant, buffer);
        push(new js.VariableUse(buffer.toString()));
      } else {
        compiler.internalError(
            "The compiler does not know how generate code for "
            "constant $constant");
      }
    } else {
      String name = namer.constantName(constant);
      js.VariableUse currentIsolateUse =
          new js.VariableUse(backend.namer.CURRENT_ISOLATE);
      push(new js.PropertyAccess.field(currentIsolateUse, name));
    }
  }

  visitConstant(HConstant node) {
    assert(isGenerateAtUseSite(node));
    generateConstant(node.constant);
  }

  visitLoopBranch(HLoopBranch node) {
    if (subGraph != null && identical(node.block, subGraph.end)) {
      // We are generating code for a loop condition.
      // If doing this as part of a SubGraph traversal, the
      // calling code will handle the control flow logic.

      // If we are generating the subgraph as an expression, the
      // condition will be generated as the expression.
      // Otherwise, we don't generate the expression, and leave that
      // to the code that called [visitSubGraph].
      if (isGeneratingExpression) {
        use(node.inputs[0]);
      }
      return;
    }
    HBasicBlock branchBlock = currentBlock;
    handleLoopCondition(node);
    List<HBasicBlock> dominated = currentBlock.dominatedBlocks;
    // For a do while loop, the body has already been visited.
    if (!node.isDoWhile()) {
      visitBasicBlock(dominated[0]);
    }
    endLoop(node.block);

    // If the branch does not dominate the code after the loop, the
    // dominator will visit it.
    if (!identical(branchBlock.successors[1].dominator, branchBlock)) return;

    visitBasicBlock(branchBlock.successors[1]);
    // With labeled breaks we can have more dominated blocks.
    if (dominated.length >= 3) {
      for (int i = 2; i < dominated.length; i++) {
        visitBasicBlock(dominated[i]);
      }
    }
  }

  visitNot(HNot node) {
    assert(node.inputs.length == 1);
    generateNot(node.inputs[0]);
    attachLocationToLast(node);
  }


  void generateNot(HInstruction input) {
    bool canGenerateOptimizedComparison(HInstruction instruction) {
      if (instruction is !HRelational) return false;
      HRelational relational = instruction;
      HInstruction left = relational.left;
      HInstruction right = relational.right;
      // This optimization doesn't work for NaN, so we only do it if the
      // type is known to be an integer.
      return relational.isBuiltin(types)
          && types[left].isUseful() && left.isInteger(types)
          && types[right].isUseful() && right.isInteger(types);
    }

    if (input is HBoolify && isGenerateAtUseSite(input)) {
      use(input.inputs[0]);
      push(new js.Binary("!==", pop(), newLiteralBool(true)), input);
    } else if (canGenerateOptimizedComparison(input) &&
               isGenerateAtUseSite(input)) {
      Map<String, String> inverseOperator = const <String, String>{
        "==" : "!=",
        "!=" : "==",
        "===": "!==",
        "!==": "===",
        "<"  : ">=",
        "<=" : ">",
        ">"  : "<=",
        ">=" : "<"
      };
      HRelational relational = input;
      BinaryOperation operation = relational.operation(backend.constantSystem);
      visitInvokeBinary(input, inverseOperator[operation.name.stringValue]);
    } else {
      use(input);
      push(new js.Prefix("!", pop()));
    }
  }

  visitParameterValue(HParameterValue node) => visitLocalValue(node);

  visitLocalValue(HLocalValue node) {
    assert(isGenerateAtUseSite(node));
    push(new js.VariableUse(variableNames.getName(node)), node);
  }

  visitPhi(HPhi node) {
    // This method is only called for phis that are generated at use
    // site. A phi can be generated at use site only if it is the
    // result of a control flow operation.
    HBasicBlock ifBlock = node.block.dominator;
    assert(controlFlowOperators.contains(ifBlock.last));
    HInstruction input = ifBlock.last.inputs[0];
    if (input.isConstantFalse()) {
      use(node.inputs[1]);
    } else if (input.isConstantTrue()) {
      use(node.inputs[0]);
    } else if (node.inputs[1].isConstantBoolean()) {
      String operation = node.inputs[1].isConstantFalse() ? '&&' : '||';
      if (operation == '||') {
        if (input is HNot) {
          use(input.inputs[0]);
        } else {
          generateNot(input);
        }
      } else {
        use(input);
      }
      js.Expression left = pop();
      use(node.inputs[0]);
      push(new js.Binary(operation, left, pop()));
    } else {
      use(input);
      js.Expression test = pop();
      use(node.inputs[0]);
      js.Expression then = pop();
      use(node.inputs[1]);
      push(new js.Conditional(test, then, pop()));
    }
  }

  visitReturn(HReturn node) {
    assert(node.inputs.length == 1);
    HInstruction input = node.inputs[0];
    if (input.isConstantNull()) {
      pushStatement(new js.Return(null), node);
    } else {
      use(node.inputs[0]);
      pushStatement(new js.Return(pop()), node);
    }
  }

  visitThis(HThis node) {
    push(new js.This());
  }

  visitThrow(HThrow node) {
    if (node.isRethrow) {
      use(node.inputs[0]);
      pushStatement(new js.Throw(pop()), node);
    } else {
      generateThrowWithHelper(r'$throw', node.inputs[0]);
    }
  }

  visitRangeConversion(HRangeConversion node) {
    // Range conversion instructions are removed by the value range
    // analyzer.
    assert(false);
  }

  visitBoundsCheck(HBoundsCheck node) {
    // TODO(ngeoffray): Separate the two checks of the bounds check, so,
    // e.g., the zero checks can be shared if possible.

    // If the checks always succeeds, we would have removed the bounds check
    // completely.
    assert(node.staticChecks != HBoundsCheck.ALWAYS_TRUE);
    if (node.staticChecks != HBoundsCheck.ALWAYS_FALSE) {
      js.Expression under;
      js.Expression over;
      if (node.staticChecks != HBoundsCheck.ALWAYS_ABOVE_ZERO) {
        use(node.index);
        under = new js.Binary("<", pop(), new js.LiteralNumber("0"));
      }
      if (node.staticChecks != HBoundsCheck.ALWAYS_BELOW_LENGTH) {
        var index = node.index;
        use(index);
        js.Expression jsIndex = pop();
        use(node.length);
        over = new js.Binary(">=", jsIndex, pop());
      }
      assert(over != null || under != null);
      js.Expression underOver = under == null
          ? over
          : over == null
              ? under
              : new js.Binary("||", under, over);
      js.Statement thenBody = new js.Block.empty();
      js.Block oldContainer = currentContainer;
      currentContainer = thenBody;
      generateThrowWithHelper('ioore', node.index);
      currentContainer = oldContainer;
      thenBody = unwrapStatement(thenBody);
      pushStatement(new js.If.noElse(underOver, thenBody), node);
    } else {
      generateThrowWithHelper('ioore', node.index);
    }
  }

  visitIntegerCheck(HIntegerCheck node) {
    if (!node.alwaysFalse) {
      checkInt(node.value, '!==');
      js.Expression test = pop();
      js.Statement thenBody = new js.Block.empty();
      js.Block oldContainer = currentContainer;
      currentContainer = thenBody;
      generateThrowWithHelper('iae', node.value);
      currentContainer = oldContainer;
      thenBody = unwrapStatement(thenBody);
      pushStatement(new js.If.noElse(test, thenBody), node);
    } else {
      generateThrowWithHelper('iae', node.value);
    }
  }

  void generateThrowWithHelper(String helperName, HInstruction argument) {
    Element helper = compiler.findHelper(new SourceString(helperName));
    world.registerStaticUse(helper);
    js.VariableUse jsHelper =
        new js.VariableUse(backend.namer.isolateAccess(helper));
    js.Call value = new js.Call(jsHelper, visitArguments([null, argument]));
    attachLocation(value, argument);
    // BUG(4906): Using throw here adds to the size of the generated code
    // but it has the advantage of explicitly telling the JS engine that
    // this code path will terminate abruptly. Needs more work.
    pushStatement(new js.Throw(value));
  }

  void visitSwitch(HSwitch node) {
    // Switches are handled using [visitSwitchInfo].
  }

  void visitStatic(HStatic node) {
    // Check whether this static is used for anything else than as a target in
    // a static call.
    node.usedBy.forEach((HInstruction instr) {
      if (instr is !HInvokeStatic) {
        backend.registerNonCallStaticUse(node);
      } else if (!identical(instr.target, node)) {
        backend.registerNonCallStaticUse(node);
      } else {
        // If invoking the static is can still be passed as an argument as well
        // which will also be non call static use.
        for (int i = 1; i < node.inputs.length; i++) {
          if (identical(node.inputs, node)) {
            backend.registerNonCallStaticUse(node);
            break;
          }
        }
      }
    });
    world.registerStaticUse(node.element);
    push(new js.VariableUse(backend.namer.isolateAccess(node.element)));
  }

  void visitLazyStatic(HLazyStatic node) {
    Element element = node.element;
    world.registerStaticUse(element);
    String lazyGetter = backend.namer.isolateLazyInitializerAccess(element);
    js.VariableUse target = new js.VariableUse(lazyGetter);
    js.Call call = new js.Call(target, <js.Expression>[]);
    push(call, node);
  }

  void visitStaticStore(HStaticStore node) {
    world.registerStaticUse(node.element);
    js.VariableUse variableUse =
        new js.VariableUse(backend.namer.isolateAccess(node.element));
    use(node.inputs[0]);
    push(new js.Assignment(variableUse, pop()), node);
  }

  void visitStringConcat(HStringConcat node) {
    if (isEmptyString(node.left)) {
      useStringified(node.right);
   } else if (isEmptyString(node.right)) {
      useStringified(node.left);
    } else {
      useStringified(node.left);
      js.Expression left = pop();
      useStringified(node.right);
      push(new js.Binary("+", left, pop()), node);
    }
  }

  bool isEmptyString(HInstruction node) {
    if (!node.isConstantString()) return false;
    HConstant constant = node;
    StringConstant string = constant.constant;
    return string.value.length == 0;
  }

  void useStringified(HInstruction node) {
    if (node.isString(types)) {
      use(node);
    } else {
      Element convertToString = compiler.findHelper(const SourceString("S"));
      world.registerStaticUse(convertToString);
      js.VariableUse variableUse =
          new js.VariableUse(backend.namer.isolateAccess(convertToString));
      use(node);
      push(new js.Call(variableUse, <js.Expression>[pop()]), node);
    }
  }

  void visitLiteralList(HLiteralList node) {
    generateArrayLiteral(node);
  }

  void generateArrayLiteral(HLiteralList node) {
    int len = node.inputs.length;
    List<js.ArrayElement> elements = <js.ArrayElement>[];
    for (int i = 0; i < len; i++) {
      use(node.inputs[i]);
      elements.add(new js.ArrayElement(i, pop()));
    }
    push(new js.ArrayInitializer(len, elements), node);
  }

  void visitIndex(HIndex node) {
    if (node.isBuiltin(types)) {
      use(node.inputs[1]);
      js.Expression receiver = pop();
      use(node.inputs[2]);
      push(new js.PropertyAccess(receiver, pop()), node);
    } else {
      visitInvokeStatic(node);
    }
  }

  void visitIndexAssign(HIndexAssign node) {
    if (node.isBuiltin(types)) {
      use(node.inputs[1]);
      js.Expression receiver = pop();
      use(node.inputs[2]);
      js.Expression index = pop();
      use(node.inputs[3]);
      push(new js.Assignment(new js.PropertyAccess(receiver, index), pop()),
           node);
    } else {
      visitInvokeStatic(node);
    }
  }

  String builtinJsName(HInvokeInterceptor interceptor) {
    // Don't count the target method or the receiver in the arity.
    int arity = interceptor.inputs.length - 2;
    HInstruction receiver = interceptor.inputs[1];
    bool isCall = interceptor.selector.isCall();
    SourceString name = interceptor.selector.name;

    if (interceptor.isLengthGetterOnStringOrArray(types)) {
      return 'length';
    } else if (interceptor.isPopCall(types)) {
      return 'pop';
    } else if (receiver.isExtendableArray(types) && isCall) {
      if (name == const SourceString('add') && arity == 1) {
        return 'push';
      }
    } else if (receiver.isString(types) && isCall) {
      if (name == const SourceString('concat') &&
          arity == 1 &&
          interceptor.inputs[2].isString(types)) {
        return '+';
      }
      if (name == const SourceString('split') &&
          arity == 1 &&
          interceptor.inputs[2].isString(types)) {
        return 'split';
      }
    }

    return null;
  }

  void visitInvokeInterceptor(HInvokeInterceptor node) {
    String builtin = builtinJsName(node);
    if (builtin != null) {
      if (builtin == '+') {
        use(node.inputs[1]);
        js.Expression left = pop();
        use(node.inputs[2]);
        push(new js.Binary("+", left, pop()), node);
      } else {
        use(node.inputs[1]);
        js.PropertyAccess access = new js.PropertyAccess.field(pop(), builtin);
        if (node.selector.isGetter()) {
          push(access, node);
          return;
        }
        List<js.Expression> arguments = <js.Expression>[];
        for (int i = 2; i < node.inputs.length; i++) {
          use(node.inputs[i]);
          arguments.add(pop());
        }
        push(new js.Call(access, arguments), node);
      }
    } else {
      return visitInvokeStatic(node);
    }
  }

  void checkInt(HInstruction input, String cmp) {
    use(input);
    js.Expression left = pop();
    use(input);
    js.Expression or0 = new js.Binary("|", pop(), new js.LiteralNumber("0"));
    push(new js.Binary(cmp, left, or0));
  }

  void checkBigInt(HInstruction input, String cmp) {
    use(input);
    js.Expression left = pop();
    use(input);
    js.Expression right = pop();
    // TODO(4984): Deal with infinity and -0.0.
    push(new js.LiteralExpression.withData('Math.floor(#) === #',
                                           <js.Expression>[left, right]));
  }

  void checkTypeOf(HInstruction input, String cmp, String typeName) {
    use(input);
    js.Expression typeOf = new js.Prefix("typeof", pop());
    push(new js.Binary(cmp, typeOf, new js.LiteralString("'$typeName'")));
  }

  void checkNum(HInstruction input, String cmp)
      => checkTypeOf(input, cmp, 'number');

  void checkDouble(HInstruction input, String cmp)  => checkNum(input, cmp);

  void checkString(HInstruction input, String cmp)
      => checkTypeOf(input, cmp, 'string');

  void checkBool(HInstruction input, String cmp)
      => checkTypeOf(input, cmp, 'boolean');

  void checkObject(HInstruction input, String cmp) {
    assert(NullConstant.JsNull == 'null');
    if (cmp == "===") {
      checkTypeOf(input, '===', 'object');
      js.Expression left = pop();
      use(input);
      js.Expression notNull = new js.Binary("!==", pop(), new js.LiteralNull());
      push(new js.Binary("&&", left, notNull));
    } else {
      assert(cmp == "!==");
      checkTypeOf(input, '!==', 'object');
      js.Expression left = pop();
      use(input);
      js.Expression eqNull = new js.Binary("===", pop(), new js.LiteralNull());
      push(new js.Binary("||", left, eqNull));
    }
  }

  void checkArray(HInstruction input, String cmp) {
    use(input);
    js.PropertyAccess constructor =
        new js.PropertyAccess.field(pop(), 'constructor');
    push(new js.Binary(cmp, constructor, new js.VariableUse('Array')));
  }

  void checkFieldExists(HInstruction input, String fieldName) {
    use(input);
    js.PropertyAccess field = new js.PropertyAccess.field(pop(), fieldName);
    // Double negate to boolify the result.
    push(new js.Prefix('!', new js.Prefix('!', field)));
  }

  void checkImmutableArray(HInstruction input) {
    checkFieldExists(input, 'immutable\$list');
  }

  void checkExtendableArray(HInstruction input) {
    checkFieldExists(input, 'fixed\$length');
  }

  void checkFixedArray(HInstruction input) {
    checkFieldExists(input, 'fixed\$length');
  }

  void checkNull(HInstruction input) {
    use(input);
    push(new js.Binary('==', pop(), new js.LiteralNull()));
  }

  void checkFunction(HInstruction input, DartType type) {
    checkTypeOf(input, '===', 'function');
    js.Expression functionTest = pop();
    checkObject(input, '===');
    js.Expression objectTest = pop();
    checkType(input, type);
    push(new js.Binary('||',
                       functionTest,
                       new js.Binary('&&', objectTest, pop())));
  }

  void checkType(HInstruction input, DartType type, {bool negative: false}) {
    world.registerIsCheck(type);
    Element element = type.element;
    use(input);
    js.PropertyAccess field =
        new js.PropertyAccess.field(pop(), backend.namer.operatorIs(element));
    if (backend.emitter.nativeEmitter.requiresNativeIsCheck(element)) {
      push(new js.Call(field, <js.Expression>[]));
      if (negative) push(new js.Prefix('!', pop()));
    } else {
      // We always negate at least once so that the result is boolified.
      push(new js.Prefix('!', field));
      // If the result is not negated, put another '!' in front.
      if (!negative) push(new js.Prefix('!', pop()));
    }
  }

  void handleNumberOrStringSupertypeCheck(HInstruction input, DartType type) {
    assert(!identical(type.element, compiler.listClass)
           && !Elements.isListSupertype(type.element, compiler)
           && !Elements.isStringOnlySupertype(type.element, compiler));
    checkNum(input, '===');
    js.Expression numberTest = pop();
    checkString(input, '===');
    js.Expression stringTest = pop();
    checkObject(input, '===');
    js.Expression objectTest = pop();
    checkType(input, type);
    push(new js.Binary('||',
                       new js.Binary('||', numberTest, stringTest),
                       new js.Binary('&&', objectTest, pop())));
  }

  void handleStringSupertypeCheck(HInstruction input, DartType type) {
    assert(!identical(type.element, compiler.listClass)
           && !Elements.isListSupertype(type.element, compiler)
           && !Elements.isNumberOrStringSupertype(type.element, compiler));
    checkString(input, '===');
    js.Expression stringTest = pop();
    checkObject(input, '===');
    js.Expression objectTest = pop();
    checkType(input, type);
    push(new js.Binary('||',
                       stringTest,
                       new js.Binary('&&', objectTest, pop())));
  }

  void handleListOrSupertypeCheck(HInstruction input, DartType type) {
    assert(!identical(type.element, compiler.stringClass)
           && !Elements.isStringOnlySupertype(type.element, compiler)
           && !Elements.isNumberOrStringSupertype(type.element, compiler));
    checkObject(input, '===');
    js.Expression objectTest = pop();
    checkArray(input, '===');
    js.Expression arrayTest = pop();
    checkType(input, type);
    push(new js.Binary('&&',
                       objectTest,
                       new js.Binary('||', arrayTest, pop())));
  }

  void visitIs(HIs node) {
    DartType type = node.typeExpression;
    world.registerIsCheck(type);
    Element element = type.element;
    if (identical(element.kind, ElementKind.TYPE_VARIABLE)) {
      compiler.unimplemented("visitIs for type variables",
                             instruction: node.expression);
    } else if (identical(element.kind, ElementKind.TYPEDEF)) {
      compiler.unimplemented("visitIs for typedefs",
                             instruction: node.expression);
    }
    LibraryElement coreLibrary = compiler.coreLibrary;
    ClassElement objectClass = compiler.objectClass;
    HInstruction input = node.expression;

    if (identical(element, objectClass) || identical(element, compiler.dynamicClass)) {
      // The constant folder also does this optimization, but we make
      // it safe by assuming it may have not run.
      push(newLiteralBool(true), node);
    } else if (element == compiler.stringClass) {
      checkString(input, '===');
      attachLocationToLast(node);
    } else if (element == compiler.doubleClass) {
      checkDouble(input, '===');
      attachLocationToLast(node);
    } else if (element == compiler.numClass) {
      checkNum(input, '===');
      attachLocationToLast(node);
    } else if (element == compiler.boolClass) {
      checkBool(input, '===');
      attachLocationToLast(node);
    } else if (element == compiler.functionClass) {
      checkFunction(input, type);
      attachLocationToLast(node);
    } else if (element == compiler.intClass) {
      // The is check in the code tells us that it might not be an
      // int. So we do a typeof first to avoid possible
      // deoptimizations on the JS engine due to the Math.floor check.
      checkNum(input, '===');
      js.Expression numTest = pop();
      checkBigInt(input, '===');
      push(new js.Binary('&&', numTest, pop()), node);
    } else if (Elements.isNumberOrStringSupertype(element, compiler)) {
      handleNumberOrStringSupertypeCheck(input, type);
      attachLocationToLast(node);
    } else if (Elements.isStringOnlySupertype(element, compiler)) {
      handleStringSupertypeCheck(input, type);
      attachLocationToLast(node);
    } else if (identical(element, compiler.listClass)
               || Elements.isListSupertype(element, compiler)) {
      handleListOrSupertypeCheck(input, type);
      attachLocationToLast(node);
    } else if (types[input].canBePrimitive() || types[input].canBeNull()) {
      checkObject(input, '===');
      js.Expression objectTest = pop();
      checkType(input, type);
      push(new js.Binary('&&', objectTest, pop()), node);
    } else {
      checkType(input, type);
      attachLocationToLast(node);
    }
    if (node.hasTypeInfo()) {
      InterfaceType interfaceType = type;
      ClassElement cls = type.element;
      Link<DartType> arguments = interfaceType.arguments;
      js.Expression result = pop();
      for (TypeVariableType typeVariable in cls.typeVariables) {
        use(node.typeInfoCall);
        // TODO(johnniwinther): Retrieve the type name properly and not through
        // [toString]. Note: Two cases below [typeVariable] and
        // [arguments.head].
        js.PropertyAccess field =
            new js.PropertyAccess.field(pop(), typeVariable.toString());
        js.Expression genericName = new js.LiteralString("'${arguments.head}'");
        js.Binary eqTest = new js.Binary('===', field, genericName);
        // Also test for 'undefined' in case the object does not have
        // any type variable.
        js.Prefix undefinedTest = new js.Prefix('!', field);
        result = new js.Binary(
            '&&', result, new js.Binary('||', undefinedTest, eqTest));
      }
      push(result, node);
    }
    if (node.nullOk) {
      checkNull(input);
      push(new js.Binary('||', pop(), pop()), node);
    }
  }

  void visitTypeConversion(HTypeConversion node) {
    Map<String, SourceString> castNames = const <String, SourceString> {
      "stringTypeCheck":
          const SourceString("stringTypeCast"),
      "doubleTypeCheck":
          const SourceString("doubleTypeCast"),
      "numTypeCheck":
          const SourceString("numTypeCast"),
      "boolTypeCheck":
          const SourceString("boolTypeCast"),
      "functionTypeCheck":
          const SourceString("functionTypeCast"),
      "intTypeCheck":
          const SourceString("intTypeCast"),
      "numberOrStringSuperNativeTypeCheck":
          const SourceString("numberOrStringSuperNativeTypeCast"),
      "numberOrStringSuperTypeCheck":
          const SourceString("numberOrStringSuperTypeCast"),
      "stringSuperNativeTypeCheck":
          const SourceString("stringSuperNativeTypeCast"),
      "stringSuperTypeCheck":
          const SourceString("stringSuperTypeCast"),
      "listTypeCheck":
          const SourceString("listTypeCast"),
      "listSuperNativeTypeCheck":
          const SourceString("listSuperNativeTypeCast"),
      "listSuperTypeCheck":
          const SourceString("listSuperTypeCast"),
      "callTypeCheck":
          const SourceString("callTypeCast"),
      "propertyTypeCheck":
          const SourceString("propertyTypeCast")
    };

    if (node.isChecked) {
      DartType type = node.type.computeType(compiler);
      Element element = type.element;
      world.registerIsCheck(type);

      if (node.isArgumentTypeCheck) {
        if (element == compiler.intClass) {
          checkInt(node.checkedInput, '!==');
        } else {
          assert(element == compiler.numClass);
          checkNum(node.checkedInput, '!==');
        }
        js.Expression test = pop();
        js.Block oldContainer = currentContainer;
        js.Statement body = new js.Block.empty();
        currentContainer = body;
        generateThrowWithHelper('iae', node.checkedInput);
        currentContainer = oldContainer;
        body = unwrapStatement(body);
        pushStatement(new js.If.noElse(test, body), node);
        return;
      }
      assert(node.isCheckedModeCheck || node.isCastTypeCheck);

      SourceString helper;
      if (node.isBooleanConversionCheck) {
        helper = const SourceString('boolConversionCheck');
      } else {
        helper = backend.getCheckedModeHelper(type);
        if (node.isCastTypeCheck) {
          helper = castNames[helper.stringValue];
        }
      }
      FunctionElement helperElement = compiler.findHelper(helper);
      world.registerStaticUse(helperElement);
      List<js.Expression> arguments = <js.Expression>[];
      use(node.checkedInput);
      arguments.add(pop());
      if (helperElement.computeSignature(compiler).parameterCount != 1) {
        String additionalArgument = backend.namer.operatorIs(element);
        arguments.add(new js.LiteralString("'$additionalArgument'"));
      }
      String helperName = backend.namer.isolateAccess(helperElement);
      push(new js.Call(new js.VariableUse(helperName), arguments));
    } else {
      use(node.checkedInput);
    }
  }
}

class SsaOptimizedCodeGenerator extends SsaCodeGenerator {
  SsaOptimizedCodeGenerator(backend, work, parameters, parameterNames)
    : super(backend, work, parameterNames) {
    // Declare the parameter names only for the optimized version. The
    // unoptimized version has different parameters.
    parameterNames.forEach((Element element, String name) {
      declaredLocals.add(name);
    });
  }

  int maxBailoutParameters;

  HBasicBlock beginGraph(HGraph graph) => graph.entry;
  void endGraph(HGraph graph) {}

  js.Statement bailout(HTypeGuard guard, String reason) {
    if (maxBailoutParameters == null) {
      maxBailoutParameters = 0;
      work.guards.forEach((HTypeGuard workGuard) {
        HBailoutTarget target = workGuard.bailoutTarget;
        int inputLength = target.inputs.length;
        if (inputLength > maxBailoutParameters) {
          maxBailoutParameters = inputLength;
        }
      });
    }
    HInstruction input = guard.guarded;
    HBailoutTarget target = guard.bailoutTarget;
    Namer namer = backend.namer;
    Element element = work.element;
    List<js.Expression> arguments = <js.Expression>[];
    arguments.add(new js.LiteralNumber("${guard.state}"));
    // TODO(ngeoffray): try to put a variable at a deterministic
    // location, so that multiple bailout calls put the variable at
    // the same parameter index.
    int i = 0;
    for (; i < target.inputs.length; i++) {
      assert(guard.inputs.indexOf(target.inputs[i]) >= 0);
      use(target.inputs[i]);
      arguments.add(pop());
    }

    js.Expression bailoutTarget;
    if (element.isInstanceMember()) {
      // TODO(ngeoffray): This does not work in case we come from a
      // super call. We must make bailout names unique.
      String bailoutName = namer.getBailoutName(element);
      bailoutTarget = new js.PropertyAccess.field(new js.This(), bailoutName);
    } else {
      assert(!element.isField());
      bailoutTarget = new js.VariableUse(namer.isolateBailoutAccess(element));
    }
    js.Call call = new js.Call(bailoutTarget, arguments);
    attachLocation(call, guard);
    return new js.Return(call);
  }

  void visitTypeGuard(HTypeGuard node) {
    HInstruction input = node.guarded;
    DartType indexingBehavior =
        backend.jsIndexingBehaviorInterface.computeType(compiler);
    if (node.isInteger(types)) {
      // if (input is !int) bailout
      checkInt(input, '!==');
      js.Statement then = bailout(node, 'Not an integer');
      pushStatement(new js.If.noElse(pop(), then), node);
    } else if (node.isNumber(types)) {
      // if (input is !num) bailout
      checkNum(input, '!==');
      js.Statement then = bailout(node, 'Not a number');
      pushStatement(new js.If.noElse(pop(), then), node);
    } else if (node.isBoolean(types)) {
      // if (input is !bool) bailout
      checkBool(input, '!==');
      js.Statement then = bailout(node, 'Not a boolean');
      pushStatement(new js.If.noElse(pop(), then), node);
    } else if (node.isString(types)) {
      // if (input is !string) bailout
      checkString(input, '!==');
      js.Statement then = bailout(node, 'Not a string');
      pushStatement(new js.If.noElse(pop(), then), node);
    } else if (node.isExtendableArray(types)) {
      // if (input is !Object || input is !Array || input.isFixed) bailout
      checkObject(input, '!==');
      js.Expression objectTest = pop();
      checkArray(input, '!==');
      js.Expression arrayTest = pop();
      checkFixedArray(input);
      js.Binary test = new js.Binary('||', objectTest, arrayTest);
      test = new js.Binary('||', test, pop());
      js.Statement then = bailout(node, 'Not an extendable array');
      pushStatement(new js.If.noElse(test, then), node);
    } else if (node.isMutableArray(types)) {
      // if (input is !Object
      //     || ((input is !Array || input.isImmutable)
      //         && input is !JsIndexingBehavior)) bailout
      checkObject(input, '!==');
      js.Expression objectTest = pop();
      checkArray(input, '!==');
      js.Expression arrayTest = pop();
      checkImmutableArray(input);
      js.Binary notArrayOrImmutable = new js.Binary('||', arrayTest, pop());
      checkType(input, indexingBehavior, negative: true);
      js.Binary notIndexing = new js.Binary('&&', notArrayOrImmutable, pop());
      js.Binary test = new js.Binary('||', objectTest, notIndexing);
      js.Statement then = bailout(node, 'Not a mutable array');
      pushStatement(new js.If.noElse(test, then), node);
    } else if (node.isReadableArray(types)) {
      // if (input is !Object
      //     || (input is !Array && input is !JsIndexingBehavior)) bailout
      checkObject(input, '!==');
      js.Expression objectTest = pop();
      checkArray(input, '!==');
      js.Expression arrayTest = pop();
      checkType(input, indexingBehavior, negative: true);
      js.Expression notIndexing = new js.Binary('&&', arrayTest, pop());
      js.Binary test = new js.Binary('||', objectTest, notIndexing);
      js.Statement then = bailout(node, 'Not an array');
      pushStatement(new js.If.noElse(test, then), node);
    } else if (node.isIndexablePrimitive(types)) {
      // if (input is !String
      //     && (input is !Object
      //         || (input is !Array && input is !JsIndexingBehavior))) bailout
      checkString(input, '!==');
      js.Expression stringTest = pop();
      checkObject(input, '!==');
      js.Expression objectTest = pop();
      checkArray(input, '!==');
      js.Expression arrayTest = pop();
      checkType(input, indexingBehavior, negative: true);
      js.Binary notIndexingTest = new js.Binary('&&', arrayTest, pop());
      js.Binary notObjectOrIndexingTest =
          new js.Binary('||', objectTest, notIndexingTest);
      js.Binary test =
          new js.Binary('&&', stringTest, notObjectOrIndexingTest);
      js.Statement then = bailout(node, 'Not a string or array');
      pushStatement(new js.If.noElse(test, then), node);
    } else {
      compiler.internalError('Unexpected type guard', instruction: input);
    }
  }

  void visitBailoutTarget(HBailoutTarget target) {
    // Do nothing. Bailout targets are only used in the non-optimized version.
  }

  void beginLoop(HBasicBlock block) {
    oldContainerStack.add(currentContainer);
    currentContainer = new js.Block.empty();
  }

  void endLoop(HBasicBlock block) {
    js.Statement body = currentContainer;
    currentContainer = oldContainerStack.removeLast();
    body = unwrapStatement(body);
    js.While loop = new js.While(newLiteralBool(true), body);

    HLoopInformation info = block.loopInformation;
    attachLocationRange(loop,
                        info.loopBlockInformation.sourcePosition,
                        info.loopBlockInformation.endSourcePosition);
    pushStatement(wrapIntoLabels(loop, info.labels));
  }

  void handleLoopCondition(HLoopBranch node) {
    use(node.inputs[0]);
    pushStatement(new js.If.noElse(pop(), new js.Break(null)), node);
  }


  void preLabeledBlock(HLabeledBlockInformation labeledBlockInfo) {
  }

  void startLabeledBlock(HLabeledBlockInformation labeledBlockInfo) {
  }

  void endLabeledBlock(HLabeledBlockInformation labeledBlockInfo) {
  }
}

class SsaUnoptimizedCodeGenerator extends SsaCodeGenerator {

  js.Statement setup;
  js.Switch currentBailoutSwitch;
  final List<js.Switch> oldBailoutSwitches;
  final List<js.Parameter> newParameters;
  final List<String> labels;
  int labelId = 0;
  /**
   * Keeps track if a bailout switch already used its [:default::] clause. New
   * bailout-switches just push [:false:] on the stack and replace it when
   * they used the [:default::] clause.
   */
  final List<bool> defaultClauseUsedInBailoutStack;

  SsaBailoutPropagator propagator;
  HInstruction savedFirstInstruction;

  SsaUnoptimizedCodeGenerator(backend, work, parameters, parameterNames)
    : super(backend, work, parameterNames),
      oldBailoutSwitches = <js.Switch>[],
      newParameters = <js.Parameter>[],
      labels = <String>[],
      defaultClauseUsedInBailoutStack = <bool>[];

  String pushLabel() {
    String label = 'L${labelId++}';
    labels.addLast(label);
    return label;
  }

  String popLabel() {
    return labels.removeLast();
  }

  String currentLabel() {
    return labels.last;
  }

  js.VariableUse generateStateUse()
      => new js.VariableUse(variableNames.stateName);

  HBasicBlock beginGraph(HGraph graph) {
    propagator = new SsaBailoutPropagator(compiler, generateAtUseSite);
    propagator.visitGraph(graph);
    // TODO(ngeoffray): We could avoid generating the state at the
    // call site for non-complex bailout methods.
    newParameters.add(new js.Parameter(variableNames.stateName));

    if (propagator.hasComplexBailoutTargets) {
      // Use generic parameters that will be assigned to
      // the right variables in the setup phase.
      for (int i = 0; i < propagator.maxBailoutParameters; i++) {
        String name = 'env$i';
        declaredLocals.add(name);
        newParameters.add(new js.Parameter(name));
      }

      startBailoutSwitch();

      // The setup phase of a bailout function sets up the environment for
      // each bailout target. Each bailout target will populate this
      // setup phase. It is put at the beginning of the function.
      setup = new js.Switch(generateStateUse(), <js.SwitchClause>[]);
      return graph.entry;
    } else {
      // We have a simple bailout target, so we can reuse the names that
      // the bailout target expects.
      for (HInstruction input in propagator.firstBailoutTarget.inputs) {
        input = unwrap(input);
        String name = variableNames.getName(input);
        declaredLocals.add(name);
        newParameters.add(new js.Parameter(name));
      }

      // We change the first instruction of the first guard to be the
      // bailout target. We will change it back in the call to [endGraph].
      HBasicBlock block = propagator.firstBailoutTarget.block;
      savedFirstInstruction = block.first;
      block.first = propagator.firstBailoutTarget;
      return block;
    }
  }

  // If argument is a [HCheck] and it does not have a name, we try to
  // find the name of its checked input. Note that there must be a
  // name, otherwise the instruction would not be in the live
  // environment.
  HInstruction unwrap(HInstruction argument) {
    while (argument is HCheck && !variableNames.hasName(argument)) {
      argument = argument.checkedInput;
    }
    assert(variableNames.hasName(argument));
    return argument;
  }

  void endGraph(HGraph graph) {
    if (propagator.hasComplexBailoutTargets) {
      endBailoutSwitch();
    } else {
      // Put back the original first instruction of the block.
      propagator.firstBailoutTarget.block.first = savedFirstInstruction;
    }
  }

  bool visitAndOrInfo(HAndOrBlockInformation info) => false;

  bool visitIfInfo(HIfBlockInformation info) {
    if (info.thenGraph.start.hasBailoutTargets()) return false;
    if (info.elseGraph.start.hasBailoutTargets()) return false;
    return super.visitIfInfo(info);
  }

  bool visitLoopInfo(HLoopBlockInformation info) {
    if (info.start.hasBailoutTargets()) return false;
    if (info.loopHeader.hasBailoutTargets()) return false;
    return super.visitLoopInfo(info);
  }

  bool visitTryInfo(HTryBlockInformation info) => false;
  bool visitSequenceInfo(HStatementSequenceInformation info) => false;

  void visitTypeGuard(HTypeGuard node) {
    // Do nothing. Type guards are only used in the optimized version.
  }

  void visitBailoutTarget(HBailoutTarget node) {
    if (!propagator.hasComplexBailoutTargets) return;

    js.Block nextBlock = new js.Block.empty();
    js.Case clause = new js.Case(new js.LiteralNumber('${node.state}'),
                                 nextBlock);
    currentBailoutSwitch.cases.add(clause);
    currentContainer = nextBlock;
    pushExpressionAsStatement(new js.Assignment(generateStateUse(),
                                                new js.LiteralNumber('0')));
    js.Block setupBlock = new js.Block.empty();
    List<Copy> copies = <Copy>[];
    for (int i = 0; i < node.inputs.length; i++) {
      HInstruction input = node.inputs[i];
      input = unwrap(input);
      String name = variableNames.getName(input);
      String source = "env$i";
      copies.add(new Copy(source, name));
    }
    sequentializeCopies(copies,
                        variableNames.getSwapTemp(),
                        (String target, String source) {
      if (!isVariableDeclared(target) && !shouldGroupVarDeclarations) {
        js.VariableInitialization init =
            new js.VariableInitialization(new js.VariableDeclaration(target),
                                          new js.VariableUse(source));
        js.Expression varList =
            new js.VariableDeclarationList(<js.VariableInitialization>[init]);
        setupBlock.statements.add(new js.ExpressionStatement(varList));
      } else {
        collectedVariableDeclarations.add(target);
        js.Expression jsTarget = new js.VariableUse(target);
        js.Expression jsSource = new js.VariableUse(source);
        js.Expression assignment = new js.Assignment(jsTarget, jsSource);
        setupBlock.statements.add(new js.ExpressionStatement(assignment));
      }
      declaredLocals.add(target);
    });
    setupBlock.statements.add(new js.Break(null));
    js.Case setupClause =
        new js.Case(new js.LiteralNumber('${node.state}'), setupBlock);
    (setup as js.Switch).cases.add(setupClause);
  }

  void startBailoutCase(List<HBailoutTarget> bailouts1,
                        [List<HBailoutTarget> bailouts2 = const []]) {
    if (!defaultClauseUsedInBailoutStack.last &&
        bailouts1.length + bailouts2.length >= 2) {
      currentContainer = new js.Block.empty();
      currentBailoutSwitch.cases.add(new js.Default(currentContainer));
      int len = defaultClauseUsedInBailoutStack.length;
      defaultClauseUsedInBailoutStack[len - 1] = true;
    } else {
      _handleBailoutCase(bailouts1);
      _handleBailoutCase(bailouts2);
      currentContainer = currentBailoutSwitch.cases.last.body;
    }
  }

  void _handleBailoutCase(List<HBailoutTarget> targets) {
    for (int i = 0, len = targets.length; i < len; i++) {
      js.LiteralNumber expr = new js.LiteralNumber('${targets[i].state}');
      currentBailoutSwitch.cases.add(new js.Case(expr, new js.Block.empty()));
    }
  }

  void startBailoutSwitch() {
    defaultClauseUsedInBailoutStack.add(false);
    oldBailoutSwitches.add(currentBailoutSwitch);
    List<js.SwitchClause> cases = <js.SwitchClause>[];
    js.Block firstBlock = new js.Block.empty();
    cases.add(new js.Case(new js.LiteralNumber("0"), firstBlock));
    currentBailoutSwitch = new js.Switch(generateStateUse(), cases);
    pushStatement(currentBailoutSwitch);
    oldContainerStack.add(currentContainer);
    currentContainer = firstBlock;
  }

  js.Switch endBailoutSwitch() {
    js.Switch result = currentBailoutSwitch;
    currentBailoutSwitch = oldBailoutSwitches.removeLast();
    defaultClauseUsedInBailoutStack.removeLast();
    currentContainer = oldContainerStack.removeLast();
    return result;
  }

  void beginLoop(HBasicBlock block) {
    String loopLabel = pushLabel();
    if (block.hasBailoutTargets()) {
      startBailoutCase(block.bailoutTargets);
    }
    oldContainerStack.add(currentContainer);
    currentContainer = new js.Block.empty();
    if (block.hasBailoutTargets()) {
      startBailoutSwitch();
      HLoopInformation loopInformation = block.loopInformation;
      if (loopInformation.target != null) {
        breakAction[loopInformation.target] = (TargetElement target) {
          pushStatement(new js.Break(loopLabel));
        };
      }
    }
  }

  void endLoop(HBasicBlock block) {
    String loopLabel = popLabel();

    HBasicBlock header = block.isLoopHeader() ? block : block.parentLoopHeader;
    HLoopInformation info = header.loopInformation;
    if (header.hasBailoutTargets()) {
      endBailoutSwitch();
      if (info.target != null) breakAction.remove(info.target);
    }

    js.Statement body = unwrapStatement(currentContainer);
    currentContainer = oldContainerStack.removeLast();

    js.Statement result = new js.While(newLiteralBool(true), body);
    attachLocationRange(result,
                        info.loopBlockInformation.sourcePosition,
                        info.loopBlockInformation.endSourcePosition);
    result = new js.LabeledStatement(loopLabel, result);
    result = wrapIntoLabels(result, info.labels);
    pushStatement(result);
  }

  void handleLoopCondition(HLoopBranch node) {
    use(node.inputs[0]);
    js.Expression test = new js.Prefix('!', pop());
    js.Statement then = new js.Break(currentLabel());
    pushStatement(new js.If.noElse(test, then), node);
  }

  void generateIf(HIf node, HIfBlockInformation info) {
    HStatementInformation thenGraph = info.thenGraph;
    HStatementInformation elseGraph = info.elseGraph;
    bool thenHasGuards = thenGraph.start.hasBailoutTargets();
    bool elseHasGuards = elseGraph.start.hasBailoutTargets();
    bool hasGuards = thenHasGuards || elseHasGuards;
    if (!hasGuards) {
      super.generateIf(node, info);
      return;
    }

    startBailoutCase(thenGraph.start.bailoutTargets,
                     elseGraph.start.bailoutTargets);

    use(node.inputs[0]);
    js.Binary stateEquals0 =
        new js.Binary('===', generateStateUse(), new js.LiteralNumber('0'));
    js.Expression condition = new js.Binary('&&', stateEquals0, pop());
    // TODO(ngeoffray): Put the condition initialization in the
    // [setup] buffer.
    List<HBailoutTarget> targets = node.thenBlock.bailoutTargets;
    for (int i = 0, len = targets.length; i < len; i++) {
      js.VariableUse stateRef = generateStateUse();
      js.Expression targetState = new js.LiteralNumber('${targets[i].state}');
      js.Binary stateTest = new js.Binary('===', stateRef, targetState);
      condition = new js.Binary('||', stateTest, condition);
    }

    js.Statement thenBody = new js.Block.empty();
    js.Block oldContainer = currentContainer;
    currentContainer = thenBody;
    if (thenHasGuards) startBailoutSwitch();
    generateStatements(thenGraph);
    if (thenHasGuards) endBailoutSwitch();
    thenBody = unwrapStatement(thenBody);

    js.Statement elseBody = null;
    elseBody = new js.Block.empty();
    currentContainer = elseBody;
    if (elseHasGuards) startBailoutSwitch();
    generateStatements(elseGraph);
    if (elseHasGuards) endBailoutSwitch();
    elseBody = unwrapStatement(elseBody);

    currentContainer = oldContainer;
    pushStatement(new js.If(condition, thenBody, elseBody), node);
  }

  void preLabeledBlock(HLabeledBlockInformation labeledBlockInfo) {
    if (labeledBlockInfo.body.start.hasBailoutTargets()) {
      indent--;
      startBailoutCase(labeledBlockInfo.body.start.bailoutTargets);
      indent++;
    }
  }

  void startLabeledBlock(HLabeledBlockInformation labeledBlockInfo) {
    if (labeledBlockInfo.body.start.hasBailoutTargets()) {
      startBailoutSwitch();
    }
  }

  void endLabeledBlock(HLabeledBlockInformation labeledBlockInfo) {
    if (labeledBlockInfo.body.start.hasBailoutTargets()) {
      endBailoutSwitch();
    }
  }
}

String singleIdentityComparison(HInstruction left,
                                HInstruction right,
                                HTypeMap propagatedTypes) {
  // Returns the single identity comparison (== or ===) or null if a more
  // complex expression is required.
  if ((left.isConstant() && left.isConstantSentinel()) ||
      (right.isConstant() && right.isConstantSentinel())) return '===';
  HType leftType = propagatedTypes[left];
  HType rightType = propagatedTypes[right];
  if (leftType.canBeNull() && rightType.canBeNull()) {
    if (left.isConstantNull() || right.isConstantNull() ||
        (leftType.isPrimitive() && leftType == rightType)) {
      return '==';
    }
    return null;
  } else {
    return '===';
  }
}
