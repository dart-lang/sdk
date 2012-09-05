// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    FunctionExpression expression = element.cachedNode;
    js.Fun result = new js.Fun(parameters, body);
    result.sourcePosition = expression.getBeginToken();
    result.endSourcePosition = expression.getEndToken();
    return result;
  }

  CodeBuffer prettyPrint(js.Node node, Element positionElement) {
    return js.prettyPrint(node, compiler, positionElement);
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
      Element element = work.element;
      js.Fun fun = new js.Fun(parameters, body);
      return prettyPrint(fun, element);
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
      parameterNames.forEach((element, name) {
        compiler.enqueuer.codegen.addToWorkList(element);
      });
      List<js.Parameter> parameters = <js.Parameter>[];
      parameterNames.forEach((element, name) {
        parameters.add(new js.Parameter(name));
      });
      addTypeParameters(work.element, parameters, parameterNames);
      String parametersString = Strings.join(parameterNames.getValues(), ", ");
      SsaOptimizedCodeGenerator codegen = new SsaOptimizedCodeGenerator(
          backend, work, parameters, parameterNames);
      codegen.visitGraph(graph);

      FunctionElement element = work.element;
      js.Block body;
      ClassElement enclosingClass = element.getEnclosingClass();
      if (element.isInstanceMember()
          && enclosingClass.isNative()
          && native.isOverriddenMethod(
              element, enclosingClass, nativeEmitter)) {
        // Record that this method is overridden. In case of optional
        // arguments, the emitter will generate stubs to handle them,
        // and needs to know if the method is overridden.
        nativeEmitter.overriddenMethods.add(element);
        StringBuffer buffer = new StringBuffer();
        String codeString = prettyPrint(codegen.body, work.element).toString();
        native.generateMethodWithPrototypeCheckForElement(
            compiler, buffer, element, codeString, parametersString);
        js.Node nativeCode = new js.LiteralStatement(buffer.toString());
        body = new js.Block(<js.Statement>[nativeCode]);
      } else {
        body = codegen.body;
      }
      js.Fun fun = buildJavaScriptFunction(element, parameters, body);
      return prettyPrint(fun, work.element);
    });
  }

  void addTypeParameters(Element element,
                        List<js.Parameter> parameters,
                        Map<Element, String> parameterNames) {
    if (element.isFactoryConstructor() || element.isGenerativeConstructor()) {
      ClassElement cls = element.enclosingElement;
      cls.typeVariables.forEach((TypeVariableType typeVariable) {
        String name = typeVariable.element.name.slowToString();
        String prefix = '';
        // Avoid collisions with real parameters of the method.
        do {
          name = JsNames.getValid('$prefix$name');
          prefix = '\$$prefix';
        } while (parameterNames.containsValue(name));
        parameterNames[typeVariable.element] = name;
        parameters.add(new js.Parameter(name));
      });
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
      addTypeParameters(work.element, parameters, parameterNames);

      SsaUnoptimizedCodeGenerator codegen = new SsaUnoptimizedCodeGenerator(
          backend, work, parameters, parameterNames);
      codegen.visitGraph(graph);

      js.Block body = new js.Block(<js.Statement>[]);
      if (codegen.setup != null) body.statements.add(codegen.setup);
      body.statements.add(codegen.body);
      js.Fun fun =
          buildJavaScriptFunction(work.element, codegen.newParameters, body);
      return prettyPrint(fun, work.element);
    });
  }

  Map<Element, String> getParameterNames(WorkItem work) {
    Map<Element, String> parameterNames = new LinkedHashMap<Element, String>();
    FunctionElement function = work.element;

    // The dom/html libraries have inline JS code that reference
    // parameter names directly. Long-term such code will be rejected.
    // Now, just don't mangle the parameter name.
    function.computeSignature(compiler).forEachParameter((Element element) {
      parameterNames[element] = function.isNative()
          ? element.name.slowToString()
          : JsNames.getValid('${element.name.slowToString()}');
    });
    return parameterNames;
  }
}

typedef void ElementAction(Element element);

class SsaCodeGenerator implements HVisitor, HBlockInformationVisitor {
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

  /**
   * While generating expressions, we can't insert variable declarations.
   * Instead we declare them at the end of the function
   */
  final Set<String> delayedVariableDeclarations;

  /**
   * Set of variables that have already been declared.
   */
  final Set<String> declaredVariables;

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
      declaredVariables = new Set<String>(),
      delayedVariableDeclarations = new Set<String>(),
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
    assert(expressionStack.isEmpty());
    if (instruction != null) {
      attachLocation(statement, instruction);
    }
    currentContainer.statements.add(statement);
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
    attachLocation(expressionStack.last(), instruction);
  }

  js.Node attachLocation(js.Node jsNode, HInstruction instruction) {
    if (instruction.sourcePosition !== null) {
      jsNode.sourcePosition = instruction.sourcePosition;
    }
    return jsNode;
  }

  js.Node attachLocationRange(js.Node jsNode, Node node) {
    jsNode.sourcePosition = node.getBeginToken();
    jsNode.endSourcePosition = node.getEndToken();
    return jsNode;
  }

  abstract visitTypeGuard(HTypeGuard node);
  abstract visitBailoutTarget(HBailoutTarget node);

  abstract beginGraph(HGraph graph);
  abstract endGraph(HGraph graph);

  abstract beginLoop(HBasicBlock block);
  abstract endLoop(HBasicBlock block);
  abstract handleLoopCondition(HLoopBranch node);

  abstract preLabeledBlock(HLabeledBlockInformation labeledBlockInfo);
  abstract startLabeledBlock(HLabeledBlockInformation labeledBlockInfo);
  abstract endLabeledBlock(HLabeledBlockInformation labeledBlockInfo);

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
  }

  visitGraph(HGraph graph) {
    preGenerateMethod(graph);
    currentGraph = graph;
    indent++;  // We are already inside a function.
    subGraph = new SubGraph(graph.entry, graph.exit);
    HBasicBlock start = beginGraph(graph);
    visitBasicBlock(start);
    if (!delayedVariableDeclarations.isEmpty()) {
      List<js.VariableInitialization> declarations =
          <js.VariableInitialization>[];
      delayedVariableDeclarations.forEach((String name) {
        declarations.add(new js.VariableInitialization(
            new js.VariableDeclaration(name), null));
      });
      pushExpressionAsStatement(new js.VariableDeclarationList(declarations));
    }
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
        assert(current is! HFieldSet || current.usedBy.isEmpty());
        if (current.usedBy.isEmpty()) {
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
          return basicBlock === limits.end ? result : TYPE_STATEMENT;
        }
      } else {
        // Expression-incompatible control flow.
        return TYPE_STATEMENT;
      }
    } while (limits.contains(basicBlock));
    return result;
  }

  bool isJSExpression(HExpressionInformation info) {
    return expressionType(info) !== TYPE_STATEMENT;
  }

  bool isJSDeclaration(HExpressionInformation info) {
    return expressionType(info) === TYPE_DECLARATION;
  }

  bool isJSCondition(HExpressionInformation info) {
    HSubExpressionBlockInformation graph = info;
    SubExpression limits = graph.subExpression;
    return expressionType(info) !== TYPE_STATEMENT &&
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
    if (sequenceElements.isEmpty()) {
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
    return declaredVariables.contains(variableName);
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
      if (!isVariableDeclared(variableName)) {
        delayedVariableDeclarations.add(variableName);
        // We can treat the variable as being declared from this point on.
        declaredVariables.add(variableName);
      }
      push(generateExpressionAssignment(variableName, value));
    } else if (!isVariableDeclared(variableName) ||
               delayedVariableDeclarations.contains(variableName)) {
      declaredVariables.add(variableName);
      delayedVariableDeclarations.remove(variableName);
      js.VariableDeclaration decl = new js.VariableDeclaration(variableName);
      js.VariableInitialization initialization =
          new js.VariableInitialization(decl, value);

      pushExpressionAsStatement(new js.VariableDeclarationList(
          <js.VariableInitialization>[initialization]));
    } else {
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
      push(new js.VariableUse(variableNames.getName(argument)), argument);
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
    if (!expressionStack.isEmpty()) {
      assert(expressionStack.length == 1);
      pushExpressionAsStatement(pop());
    }
  }

  void continueAsBreak(LabelElement target) {
    pushStatement(new js.Break(compiler.namer.continueLabelName(target)));
  }

  void implicitContinueAsBreak(TargetElement target) {
    pushStatement(new js.Break(
        compiler.namer.implicitContinueLabelName(target)));
  }

  void implicitBreakWithLabel(TargetElement target) {
    pushStatement(new js.Break(compiler.namer.implicitBreakLabelName(target)));
  }

  js.Statement wrapIntoLabels(js.Statement result, List<LabelElement> labels) {
    for (LabelElement label in labels) {
      if (label.isTarget) {
        String breakLabelString = compiler.namer.breakLabelName(label);
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
    if (info.catchBlock !== null) {
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
      case HLoopBlockInformation.FOR_IN_LOOP: {
        HBlockInformation initialization = info.initializer;
        int initializationType = TYPE_STATEMENT;
        if (initialization !== null) {
          initializationType = expressionType(initialization);
          if (initializationType == TYPE_STATEMENT) {
            generateStatements(initialization);
            initialization = null;
          }
        }
        if (isConditionExpression &&
            info.updates !== null && isJSExpression(info.updates)) {
          // If we have an updates graph, and it's expressible as an
          // expression, generate a for-loop.
          js.Expression jsInitialization = null;
          if (initialization !== null) {
            int delayedVariablesCount = delayedVariableDeclarations.length;
            jsInitialization = generateExpression(initialization);
            if (delayedVariablesCount < delayedVariableDeclarations.length) {
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
                  delayedVariableDeclarations.remove(id);
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
          if (initialization !== null) {
            generateStatements(initialization);
          }
          js.Expression jsCondition;
          js.Block oldContainer = currentContainer;
          js.Statement body = new js.Block.empty();
          if (isConditionExpression) {
            jsCondition = generateExpression(condition);
            currentContainer = body;
          } else {
            jsCondition = new js.LiteralBool(true);
            currentContainer = body;
            generateStatements(condition);
            use(condition.conditionExpression);
            js.Expression ifTest = new js.Prefix("!", pop());
            js.Break jsBreak = new js.Break(null);
            pushStatement(new js.If.noElse(ifTest, jsBreak));
          }
          if (info.updates !== null) {
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
      }
      case HLoopBlockInformation.DO_WHILE_LOOP: {
        // Generate do-while loop in all cases.
        if (info.initializer !== null) {
          generateStatements(info.initializer);
        }
        js.Block oldContainer = currentContainer;
        js.Statement body = new js.Block.empty();
        currentContainer = body;
        if (!isConditionExpression || info.updates !== null) {
          wrapLoopBodyForContinue(info);
        } else {
          visitBodyIgnoreLabels(info);
        }
        if (info.updates !== null) {
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
      }
      default:
        compiler.internalError(
          'Unexpected loop kind: ${info.kind}',
          instruction: condition.conditionExpression);
    }
    attachLocationRange(loop, info.sourcePosition);
    pushStatement(wrapIntoLabels(loop, info.labels));
    return true;
  }

  bool visitLabeledBlockInfo(HLabeledBlockInformation labeledBlockInfo) {
    preLabeledBlock(labeledBlockInfo);
    Link<Element> continueOverrides = const EmptyLink<Element>();

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
          String labelName = compiler.namer.continueLabelName(label);
          result = new js.LabeledStatement(labelName, result);
          continueAction[label] = continueAsBreak;
          continueOverrides = continueOverrides.prepend(label);
        }
      }
      // For handling unlabeled continues from the body of a loop.
      // TODO(lrn): Consider recording whether the target is in fact
      // a target of an unlabeled continue, and not generate this if it isn't.
      TargetElement target = labeledBlockInfo.target;
      String labelName = compiler.namer.implicitContinueLabelName(target);
      result = new js.LabeledStatement(labelName, result);
      continueAction[target] = implicitContinueAsBreak;
      continueOverrides = continueOverrides.prepend(target);
    } else {
      for (LabelElement label in labeledBlockInfo.labels) {
        if (label.isBreakTarget) {
          String labelName = compiler.namer.breakLabelName(label);
          result = new js.LabeledStatement(labelName, result);
        }
      }
      TargetElement target = labeledBlockInfo.target;
      if (target.isSwitch) {
        // This is an extra block around a switch that is generated
        // as a nested if/else chain. We add an extra break target
        // so that case code can break.
        String labelName = compiler.namer.implicitBreakLabelName(target);
        result = new js.LabeledStatement(labelName, result);
        breakAction[target] = implicitBreakWithLabel;
      }
    }

    currentContainer = body;
    startLabeledBlock(labeledBlockInfo);
    generateStatements(labeledBlockInfo.body);
    endLabeledBlock(labeledBlockInfo);

    if (labeledBlockInfo.isContinue) {
      while (!continueOverrides.isEmpty()) {
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
    if (target !== null && target.isContinueTarget) {
      js.Block oldContainer = currentContainer;
      js.Block body = new js.Block.empty();
      currentContainer = body;
      js.Statement result = body;
      for (LabelElement label in info.labels) {
        if (label.isContinueTarget) {
          String labelName = compiler.namer.continueLabelName(label);
          result = new js.LabeledStatement(labelName, result);
          continueAction[label] = continueAsBreak;
        }
      }
      String labelName = compiler.namer.implicitContinueLabelName(target);
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
    if (info === currentBlockInformation) return false;

    HBlockInformation oldBlockInformation = currentBlockInformation;
    currentBlockInformation = info;
    bool success = info.accept(this);
    currentBlockInformation = oldBlockInformation;
    if (success) {
      HBasicBlock continuation = block.continuation;
      if (continuation !== null) {
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
    if (node.blockFlow !== null &&
        handleBlockFlow(node.blockFlow)) {
      return;
    }
    // Flow based traversal.
    if (node.isLoopHeader() &&
        node.loopInformation.loopBlockInformation !== currentBlockInformation) {
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
  void sequentializeCopies(List<Copy> copies) {
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
      String sourceName = variableNames.getName(copy.source);
      String destinationName = variableNames.getName(copy.destination);
      if (sourceName != destinationName) {
        prunedCopies.add(new Copy(sourceName, destinationName));
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
      if (currentLocation[copy.destination] === null) {
        ready.add(copy.destination);
      }
    }

    while (!worklist.isEmpty()) {
      while (!ready.isEmpty()) {
        String destination = ready.removeLast();
        String source = initialValue[destination];
        // Since [source] might have been updated, use the current
        // location of [source]
        String copy = currentLocation[source];
        emitAssignment(destination, copy);
        // Now [destination] is the current location of [source].
        currentLocation[source] = destination;
        // If [source] hasn't been updated and needs to have a value,
        // add it to the list of variables that can be updated. Copies
        // of [source] will now use [destination].
        if (source == copy && initialValue[source] !== null) {
          ready.add(source);
        }
      }

      // Check if we have a cycle.
      String current = worklist.removeLast();
      // If [current] is used as a source, and the assignment has been
      // done, we are done with this variable. Otherwise there is a
      // cycle that we break by using a temporary name.
      if (currentLocation[current] !== null
          && current != currentLocation[initialValue[current]]) {
        String tempName = variableNames.swapTemp;
        emitAssignment(tempName, current);
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

    sequentializeCopies(handler.copies);

    for (Copy copy in handler.assignments) {
      String name = variableNames.getName(copy.destination);
      use(copy.source);
      assignVariable(name, pop());
    }
  }

  void iterateBasicBlock(HBasicBlock node) {
    HInstruction instruction = node.first;
    while (instruction !== node.last) {
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
    push(new js.Binary('===', pop(), new js.LiteralBool(true)), node);
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
    if (dominated.isEmpty()) return;
    if (dominated.length > 2) {
      compiler.internalError('dominated.length = ${dominated.length}',
                             instruction: node);
    }
    if (dominated.length == 2 && currentBlock !== currentGraph.entry) {
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
    if (action === null) return false;
    action(element);
    return true;
  }

  visitBreak(HBreak node) {
    assert(currentBlock.successors.length == 1);
    if (node.label !== null) {
      LabelElement label = node.label;
      if (!tryCallAction(breakAction, label)) {
        pushStatement(new js.Break(compiler.namer.breakLabelName(label)), node);
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
    if (node.label !== null) {
      LabelElement label = node.label;
      if (!tryCallAction(continueAction, label)) {
        // TODO(floitsch): should this really be the breakLabelName?
        pushStatement(new js.Continue(compiler.namer.breakLabelName(label)),
                      node);
      }
    } else {
      TargetElement target = node.target;
      if (!tryCallAction(continueAction, target)) {
        pushStatement(new js.Continue(null), node);
      }
    }
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
    if (joinBlock !== null && joinBlock.dominator !== node.block) {
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

    // Avoid adding the generative constructor name to the list of
    // seen selectors.
    if (node.inputs[0] is HForeignNew) {
      // TODO(ahe): The constructor name was statically resolved in
      // SsaBuilder.buildFactory. Is there a cleaner way to do this?
      methodName = name.slowToString();
      arguments = visitArguments(node.inputs);
    } else {
      methodName = compiler.namer.instanceMethodInvocationName(
          node.selector.library, name, node.selector);
      arguments = visitArguments(node.inputs);
      bool inLoop = node.block.enclosingLoopHeader !== null;

      // Register this invocation to collect the types used at all call sites.
      Selector selector = getOptimizedSelectorFor(node, node.selector);
      backend.registerDynamicInvocation(node, selector, types);

      // If we don't know what we're calling or if we are calling a getter,
      // we need to register that fact that we may be calling a closure
      // with the same arguments.
      Element target = node.element;
      if (target === null || target.isGetter()) {
        // TODO(kasperl): If we have a typed selector for the call, we
        // may know something about the types of closures that need
        // the specific closure call method.
        Selector call = new Selector.callClosureFrom(selector);
        world.registerDynamicInvocation(call.name, call);
      }

      if (target !== null) {
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
    HType receiverHType = types[node.inputs[0]];
    DartType receiverType = receiverHType.computeType(compiler);
    if (receiverType !== null) {
      return new TypedSelector(receiverType, defaultSelector);
    } else {
      return defaultSelector;
    }
  }

  visitInvokeDynamicSetter(HInvokeDynamicSetter node) {
    use(node.receiver);
    Selector setter = node.selector;
    String name = compiler.namer.setterName(setter.library, setter.name);
    push(jsPropertyCall(pop(), name, visitArguments(node.inputs)), node);
    world.registerDynamicSetter(
        setter.name, getOptimizedSelectorFor(node, setter));
  }

  visitInvokeDynamicGetter(HInvokeDynamicGetter node) {
    use(node.receiver);
    Selector getter = node.selector;
    String name = compiler.namer.getterName(getter.library, getter.name);
    push(jsPropertyCall(pop(), name, visitArguments(node.inputs)), node);
    world.registerDynamicGetter(
        getter.name, getOptimizedSelectorFor(node, getter));
  }

  visitInvokeClosure(HInvokeClosure node) {
    use(node.receiver);
    push(jsPropertyCall(pop(),
                        compiler.namer.closureInvocationName(node.selector),
                        visitArguments(node.inputs)),
         node);
    Selector call = new Selector.callClosureFrom(node.selector);
    world.registerDynamicInvocation(call.name, call);
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
    // Remove the element and 'this'.
    int argumentCount = node.inputs.length - 2;
    if (superMethod.kind == ElementKind.FIELD) {
      ClassElement currentClass = work.element.getEnclosingClass();
      if (currentClass.isClosure()) {
        ClosureClassElement closure = currentClass;
        currentClass = closure.methodElement.getEnclosingClass();
      }
      String fieldName;
      if (currentClass.isShadowedByField(superMethod)) {
        fieldName = compiler.namer.shadowedFieldName(superMethod);
      } else {
        LibraryElement library = superMethod.getLibrary();
        SourceString name = superMethod.name;
        fieldName = compiler.namer.instanceFieldName(library, name);
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
        methodName = compiler.namer.instanceMethodName(
            currentLibrary, superMethod.name, argumentCount);
      } else if (superMethod.kind == ElementKind.GETTER) {
        methodName =
            compiler.namer.getterName(currentLibrary, superMethod.name);
      } else {
        assert(superMethod.kind == ElementKind.SETTER);
        methodName =
            compiler.namer.setterName(currentLibrary, superMethod.name);
      }
      String className = compiler.namer.isolateAccess(superClass);
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
    String name = compiler.namer.getName(node.element);
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
    if (value.guaranteedType.union(HType.NUMBER) == HType.NUMBER) return true;
    if (value is HBinaryArithmetic) {
      return (isSimpleFieldNumberComputation(value.left, node) &&
              isSimpleFieldNumberComputation(value.right, node));
    }
    if (value is HFieldGet) return value.element == node.element;
    return false;
  }

  visitFieldSet(HFieldSet node) {
    if (work.element.isGenerativeConstructorBody() &&
        node.element.isMember() &&
        node.value.hasGuaranteedType() &&
        node.block.dominates(currentGraph.exit)) {
      backend.updateFieldConstructorSetters(node.element,
                                            node.value.guaranteedType);
    }
    String name = compiler.namer.getName(node.element);
    DartType type = types[node.receiver].computeType(compiler);
    if (type != null) {
      if (!work.element.isGenerativeConstructorBody()) {
        world.registerFieldSetter(
            node.element.name, node.element.getLibrary(), type);
      }
      // Determine the types seen so far for the field. If only number
      // types have been seen and the value of the field set is a
      // simple number computation only depending on that field, we
      // can safely keep the number type for the field.
      HType fieldSettersType = backend.fieldSettersTypeSoFar(node.element);
      HType initializersType =
          backend.typeFromInitializersSoFar(node.element);
      HType fieldType = fieldSettersType.union(initializersType);
      if (HType.NUMBER.union(fieldType) == HType.NUMBER &&
          isSimpleFieldNumberComputation(node.value, node)) {
        backend.updateFieldSetters(node.element, HType.NUMBER);
      } else {
        backend.updateFieldSetters(node.element, types[node.value]);
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
    String code = node.code.slowToString();
    List<HInstruction> inputs = node.inputs;
    if (node.isJsStatement(types)) {
      if (!inputs.isEmpty()) {
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
    int j = 0;
    node.element.forEachInstanceField(
      includeBackendMembers: true,
      includeSuperMembers: true,
      f: (ClassElement enclosingClass, Element member) {
        backend.updateFieldInitializers(member, types[node.inputs[j]]);
        j++;
      });
    String jsClassReference = compiler.namer.isolateAccess(node.element);
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

  void generateConstant(Constant constant) {
    ConstantHandler handler = compiler.constantHandler;
    String name = handler.getNameForConstant(constant);
    if (name === null) {
      assert(!constant.isObject());
      if (constant.isBool()) {
        push(new js.LiteralBool((constant as BoolConstant).value));
      } else if (constant.isNum()) {
        // TODO(floitsch): get rid of the code buffer.
        CodeBuffer buffer = new CodeBuffer();
        handler.writeConstant(buffer, constant);
        push(new js.LiteralNumber(buffer.toString()));
      } else if (constant.isNull()) {
        push(new js.LiteralNull());
      } else if (constant.isString()) {
        // TODO(floitsch): get rid of the code buffer.
        CodeBuffer buffer = new CodeBuffer();
        handler.writeConstant(buffer, constant);
        push(new js.LiteralString(buffer.toString()));
      } else if (constant.isFunction()) {
        FunctionConstant function = constant;
        world.registerStaticUse(function.element);
        push(new js.VariableUse(
            compiler.namer.isolateAccess(function.element)));
      } else if (constant.isSentinel()) {
        // TODO(floitsch): get rid of the code buffer.
        CodeBuffer buffer = new CodeBuffer();
        handler.writeConstant(buffer, constant);
        push(new js.VariableUse(buffer.toString()));
      } else {
        compiler.internalError(
            "The compiler does not know how generate code for "
            "constant $constant");
      }
    } else {
      js.VariableUse currentIsolateUse =
          new js.VariableUse(compiler.namer.CURRENT_ISOLATE);
      push(new js.PropertyAccess.field(currentIsolateUse, name));
    }
  }

  visitConstant(HConstant node) {
    assert(isGenerateAtUseSite(node));
    generateConstant(node.constant);
  }

  visitLoopBranch(HLoopBranch node) {
    if (subGraph !== null && node.block === subGraph.end) {
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
    if (branchBlock.successors[1].dominator !== branchBlock) return;

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
    bool isBuiltinRelational(HInstruction instruction) {
      if (instruction is !HRelational) return false;
      HRelational relational = instruction;
      return relational.isBuiltin(types);
    }

    if (input is HBoolify && isGenerateAtUseSite(input)) {
      use(input.inputs[0]);
      push(new js.Binary("!==", pop(), new js.LiteralBool(true)), input);
    } else if (isBuiltinRelational(input) &&
               isGenerateAtUseSite(input) &&
               types[input.inputs[0]].isUseful() &&
               !input.inputs[0].isDouble(types) &&
               types[input.inputs[1]].isUseful() &&
               !input.inputs[1].isDouble(types)) {
      // This optimization doesn't work for NaN, so we only do it if the
      // type is known to be non-Double.
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
      visitInvokeBinary(input,
                        inverseOperator[relational.operation.name.stringValue]);
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
      generateThrowWithHelper(@'$throw', node.inputs[0]);
    }
  }

  visitBoundsCheck(HBoundsCheck node) {
    // TODO(ngeoffray): Separate the two checks of the bounds check, so,
    // e.g., the zero checks can be shared if possible.

    // If the checks always succeeds, we would have removed the bounds check
    // completely.
    assert(node.staticChecks != HBoundsCheck.ALWAYS_TRUE);
    if (node.staticChecks != HBoundsCheck.ALWAYS_FALSE) {
      js.Binary under;
      if (node.staticChecks != HBoundsCheck.ALWAYS_ABOVE_ZERO) {
        assert(node.staticChecks == HBoundsCheck.FULL_CHECK);
        use(node.index);
        under = new js.Binary("<", pop(), new js.LiteralNumber("0"));
      }
      use(node.index);
      js.Expression index = pop();
      use(node.length);
      js.Binary over = new js.Binary(">=", index, pop());
      js.Binary underOver =
          under == null ? over : new js.Binary("||", under, over);
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
        new js.VariableUse(compiler.namer.isolateAccess(helper));
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
      } else if (instr.target !== node) {
        backend.registerNonCallStaticUse(node);
      } else {
        // If invoking the static is can still be passed as an argument as well
        // which will also be non call static use.
        for (int i = 1; i < node.inputs.length; i++) {
          if (node.inputs === node) {
            backend.registerNonCallStaticUse(node);
            break;
          }
        }
      }
    });
    world.registerStaticUse(node.element);
    push(new js.VariableUse(compiler.namer.isolateAccess(node.element)));
  }

  void visitLazyStatic(HLazyStatic node) {
    Element element = node.element;
    world.registerStaticUse(element);
    String lazyGetter = compiler.namer.isolateLazyInitializerAccess(element);
    js.VariableUse target = new js.VariableUse(lazyGetter);
    js.Call call = new js.Call(target, <js.Expression>[]);
    push(call, node);
  }

  void visitStaticStore(HStaticStore node) {
    world.registerStaticUse(node.element);
    js.VariableUse variableUse =
        new js.VariableUse(compiler.namer.isolateAccess(node.element));
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
          new js.VariableUse(compiler.namer.isolateAccess(convertToString));
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
    } else if (receiver.isExtendableArray(types) && isCall) {
      if (name == const SourceString('add') && arity == 1) {
        return 'push';
      }
      if (name == const SourceString('removeLast') && arity == 0) {
        return 'pop';
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
    if (builtin !== null) {
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

  void checkFunction(HInstruction input, Element element) {
    checkTypeOf(input, '===', 'function');
    js.Expression functionTest = pop();
    checkObject(input, '===');
    js.Expression objectTest = pop();
    checkType(input, element);
    push(new js.Binary('||',
                       functionTest,
                       new js.Binary('&&', objectTest, pop())));
  }

  void checkType(HInstruction input, Element element, [bool negative = false]) {
    world.registerIsCheck(element);
    use(input);
    js.PropertyAccess field =
        new js.PropertyAccess.field(pop(), compiler.namer.operatorIs(element));
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

  void handleStringSupertypeCheck(HInstruction input, Element element) {
    // Make sure List and String don't share supertypes, otherwise we
    // would need to check for List too.
    assert(element !== compiler.listClass
           && !Elements.isListSupertype(element, compiler));
    checkString(input, '===');
    js.Expression stringTest = pop();
    checkObject(input, '===');
    js.Expression objectTest = pop();
    checkType(input, element);
    push(new js.Binary('||',
                       stringTest,
                       new js.Binary('&&', objectTest, pop())));
  }

  void handleListOrSupertypeCheck(HInstruction input, Element element) {
    // Make sure List and String don't share supertypes, otherwise we
    // would need to check for String too.
    assert(element !== compiler.stringClass
           && !Elements.isStringSupertype(element, compiler));
    checkObject(input, '===');
    js.Expression objectTest = pop();
    checkArray(input, '===');
    js.Expression arrayTest = pop();
    checkType(input, element);
    push(new js.Binary('&&',
                       objectTest,
                       new js.Binary('||', arrayTest, pop())));
  }

  void visitIs(HIs node) {
    DartType type = node.typeExpression;
    Element element = type.element;
    if (element.kind === ElementKind.TYPE_VARIABLE) {
      compiler.unimplemented("visitIs for type variables", instruction: node);
    } else if (element.kind === ElementKind.TYPEDEF) {
      compiler.unimplemented("visitIs for typedefs", instruction: node);
    }
    LibraryElement coreLibrary = compiler.coreLibrary;
    ClassElement objectClass = compiler.objectClass;
    HInstruction input = node.expression;

    if (element === objectClass || element === compiler.dynamicClass) {
      // The constant folder also does this optimization, but we make
      // it safe by assuming it may have not run.
      push(new js.LiteralBool(true), node);
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
      checkFunction(input, element);
      attachLocationToLast(node);
    } else if (element == compiler.intClass) {
      checkNum(input, '===');
      js.Expression numTest = pop();
      checkInt(input, '===');
      push(new js.Binary('&&', numTest, pop()), node);
    } else if (Elements.isStringSupertype(element, compiler)) {
      handleStringSupertypeCheck(input, element);
      attachLocationToLast(node);
    } else if (element === compiler.listClass
               || Elements.isListSupertype(element, compiler)) {
      handleListOrSupertypeCheck(input, element);
      attachLocationToLast(node);
    } else if (types[input].canBePrimitive() || types[input].canBeNull()) {
      checkObject(input, '===');
      js.Expression objectTest = pop();
      checkType(input, element);
      push(new js.Binary('&&', objectTest, pop()), node);
    } else {
      checkType(input, element);
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
        result = new js.Binary('&&', result, eqTest);
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
      world.registerIsCheck(element);

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
      SourceString helper = backend.getCheckedModeHelper(type);
      String additionalArgument = compiler.namer.operatorIs(element);
      if (node.isCastTypeCheck) {
        helper = castNames[helper.stringValue];
      }
      Element helperElement = compiler.findHelper(helper);
      world.registerStaticUse(helperElement);
      List<js.Expression> arguments = <js.Expression>[];
      use(node.checkedInput);
      arguments.add(pop());
      arguments.add(new js.LiteralString("'$additionalArgument'"));
      String helperName = compiler.namer.isolateAccess(helperElement);
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
      declaredVariables.add(name);
    });
  }

  int maxBailoutParameters;

  HBasicBlock beginGraph(HGraph graph) => graph.entry;
  void endGraph(HGraph graph) {}

  js.Statement bailout(HTypeGuard guard, String reason) {
    if (maxBailoutParameters === null) {
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
    Namer namer = compiler.namer;
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
    // Make sure we call the bailout method with the number of
    // arguments it expects. This avoids having the underlying
    // JS engine fill them in for us.
    for (; i < maxBailoutParameters; i++) {
      arguments.add(new js.LiteralNumber('0'));
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
    Element indexingBehavior = compiler.jsIndexingBehaviorInterface;
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
    js.While loop = new js.While(new js.LiteralBool(true), body);

    HLoopInformation info = block.loopInformation;
    attachLocationRange(loop, info.loopBlockInformation.sourcePosition);
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
    return labels.last();
  }

  HBasicBlock beginGraph(HGraph graph) {
    propagator = new SsaBailoutPropagator(compiler, generateAtUseSite);
    propagator.visitGraph(graph);
    // TODO(ngeoffray): We could avoid generating the state at the
    // call site for non-complex bailout methods.
    newParameters.add(new js.Parameter('state'));

    if (propagator.hasComplexBailoutTargets) {
      // Use generic parameters that will be assigned to
      // the right variables in the setup phase.
      for (int i = 0; i < propagator.maxBailoutParameters; i++) {
        String name = 'env$i';
        declaredVariables.add(name);
        newParameters.add(new js.Parameter(name));
      }

      startBailoutSwitch();

      // The setup phase of a bailout function sets up the environment for
      // each bailout target. Each bailout target will populate this
      // setup phase. It is put at the beginning of the function.
      setup = new js.Switch(new js.VariableUse('state'), <js.SwitchClause>[]);
      return graph.entry;
    } else {
      // We have a simple bailout target, so we can reuse the names that
      // the bailout target expects.
      for (HInstruction input in propagator.firstBailoutTarget.inputs) {
        input = unwrap(input);
        String name = variableNames.getName(input);
        declaredVariables.add(name);
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
    pushExpressionAsStatement(new js.Assignment(new js.VariableUse('state'),
                                                new js.LiteralNumber('0')));
    js.Block setupBlock = new js.Block.empty();
    int i = 0;
    for (HInstruction input in node.inputs) {
      input = unwrap(input);
      String name = variableNames.getName(input);
      if (!isVariableDeclared(name)) {
        declaredVariables.add(name);
        js.VariableInitialization init =
            new js.VariableInitialization(new js.VariableDeclaration(name),
                                          new js.VariableUse('env$i'));
        js.Expression varList =
            new js.VariableDeclarationList(<js.VariableInitialization>[init]);
        setupBlock.statements.add(new js.ExpressionStatement(varList));
      } else {
        js.Expression target = new js.VariableUse(name);
        js.Expression source = new js.VariableUse('env$i');
        js.Expression assignment = new js.Assignment(target, source);
        setupBlock.statements.add(new js.ExpressionStatement(assignment));
      }
      i++;
    }
    setupBlock.statements.add(new js.Break(null));
    js.Case setupClause =
        new js.Case(new js.LiteralNumber('${node.state}'), setupBlock);
    (setup as js.Switch).cases.add(setupClause);
  }

  void startBailoutCase(List<HBailoutTarget> bailouts1,
                        [List<HBailoutTarget> bailouts2 = const []]) {
    if (!defaultClauseUsedInBailoutStack.last() &&
        bailouts1.length + bailouts2.length >= 2) {
      currentContainer = new js.Block.empty();
      currentBailoutSwitch.cases.add(new js.Default(currentContainer));
      int len = defaultClauseUsedInBailoutStack.length;
      defaultClauseUsedInBailoutStack[len - 1] = true;
    } else {
      _handleBailoutCase(bailouts1);
      _handleBailoutCase(bailouts2);
      currentContainer = currentBailoutSwitch.cases.last().body;
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
    currentBailoutSwitch = new js.Switch(new js.VariableUse('state'), cases);
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
      if (loopInformation.target !== null) {
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

    js.Statement result = new js.While(new js.LiteralBool(true), body);
    attachLocationRange(result, info.loopBlockInformation.sourcePosition);
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
        new js.Binary('===',
                      new js.VariableUse('state'), new js.LiteralNumber('0'));
    js.Expression condition = new js.Binary('&&', stateEquals0, pop());
    // TODO(ngeoffray): Put the condition initialization in the
    // [setup] buffer.
    List<HBailoutTarget> targets = node.thenBlock.bailoutTargets;
    for (int i = 0, len = targets.length; i < len; i++) {
      js.VariableUse stateRef = new js.VariableUse('state');
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
