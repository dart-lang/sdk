// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SsaCodeGeneratorTask extends CompilerTask {
  SsaCodeGeneratorTask(Compiler compiler) : super(compiler);
  String get name() => 'SSA code generator';


  String generateMethod(WorkItem work, HGraph graph) {
    return measure(() {
      compiler.tracer.traceGraph("codegen", graph);
      Map<Element, String> parameterNames = getParameterNames(work);
      String parameters = Strings.join(parameterNames.getValues(), ', ');
      SsaOptimizedCodeGenerator codegen = new SsaOptimizedCodeGenerator(
          compiler, work, parameters, parameterNames);
      codegen.visitGraph(graph);
      return 'function($parameters) {\n${codegen.buffer}}';
    });
  }

  String generateBailoutMethod(WorkItem work, HGraph graph) {
    return measure(() {
      compiler.tracer.traceGraph("codegen-bailout", graph);
      new SsaBailoutPropagator(compiler).visitGraph(graph);

      Map<Element, String> parameterNames = getParameterNames(work);
      String parameters = Strings.join(parameterNames.getValues(), ', ');
      SsaUnoptimizedCodeGenerator codegen = new SsaUnoptimizedCodeGenerator(
          compiler, work, parameters, parameterNames);
      codegen.visitGraph(graph);

      StringBuffer newParameters = new StringBuffer();
      if (!parameterNames.isEmpty()) newParameters.add('$parameters, ');
      newParameters.add('state');

      for (int i = 0; i < codegen.maxBailoutParameters; i++) {
        newParameters.add(', env$i');
      }

      return 'function($newParameters) {\n${codegen.setup}${codegen.buffer}}';
    });
  }

  Map<Element, String> getParameterNames(WorkItem work) {
    Map<Element, String> parameterNames = new LinkedHashMap<Element, String>();
    FunctionElement function = work.element;

    // The dom/html libraries have inline JS code that reference
    // parameter names directly. Long-term such code will be rejected.
    // Now, just don't mangle the parameter name.
    function.computeParameters(compiler).forEachParameter((Element element) {
      parameterNames[element] = function.isNative()
          ? element.name.slowToString()
          : JsNames.getValid('${element.name.slowToString()}');
    });
    return parameterNames;
  }
}

typedef void ElementAction(Element element);

class SsaCodeGenerator implements HVisitor {
  /**
   * Current state for generating simple (non-local-control) code.
   * It is generated as either statements (indented and ';'-terminated),
   * expressions (comma separated) or declarations (also comma separated,
   * but expected to be preceeded by a 'var' so it declares its variables);
   */
  static final int STATE_STATEMENT = 0;
  static final int STATE_FIRST_EXPRESSION = 1;
  static final int STATE_FIRST_DECLARATION = 2;
  static final int STATE_EXPRESSION = 3;
  static final int STATE_DECLARATION = 4;

  final Compiler compiler;
  final WorkItem work;
  final StringBuffer buffer;
  final String parameters;

  final Map<Element, String> parameterNames;
  final Map<int, String> names;
  final Map<String, int> prefixes;
  final Set<HInstruction> generateAtUseSite;
  final Map<HPhi, String> logicalOperations;
  final Map<Element, ElementAction> breakAction;
  final Map<Element, ElementAction> continueAction;

  Element equalsNullElement;
  int indent = 0;
  int expectedPrecedence = JSPrecedence.STATEMENT_PRECEDENCE;
  HGraph currentGraph;
  /**
   * Whether the code-generation should try to generate an expression
   * instead of a sequence of statements.
   */
  int generationState = STATE_STATEMENT;
  /**
   * While generating expressions, we can't insert variable declarations.
   * Instead we declare them at the end of the function
   */
  Link<String> delayedVarDecl = const EmptyLink<String>();
  HBasicBlock currentBlock;

  // Records a block-information that is being handled specially.
  // Used to break bad recursion.
  HBlockInformation currentBlockInformation;
  // The subgraph is used to delimit traversal for some constructions, e.g.,
  // if branches.
  SubGraph subGraph;

  LibraryElement get currentLibrary() => work.element.getLibrary();

  bool isGenerateAtUseSite(HInstruction instruction) {
    return generateAtUseSite.contains(instruction);
  }

  SsaCodeGenerator(this.compiler,
                   this.work,
                   this.parameters,
                   this.parameterNames)
    : names = new Map<int, String>(),
      prefixes = new Map<String, int>(),
      buffer = new StringBuffer(),
      generateAtUseSite = new Set<HInstruction>(),
      logicalOperations = new Map<HPhi, String>(),
      breakAction = new Map<Element, ElementAction>(),
      continueAction = new Map<Element, ElementAction>() {

    for (final name in parameterNames.getValues()) {
      prefixes[name] = 0;
    }

    equalsNullElement =
        compiler.builder.interceptors.getEqualsNullInterceptor();
  }

  abstract visitTypeGuard(HTypeGuard node);

  abstract beginGraph(HGraph graph);
  abstract endGraph(HGraph graph);

  abstract beginLoop(HBasicBlock block);
  abstract endLoop(HBasicBlock block);
  abstract handleLoopCondition(HLoopBranch node);

  abstract startIf(HIf node);
  abstract endIf(HIf node);
  abstract startThen(HIf node);
  abstract endThen(HIf node);
  abstract startElse(HIf node);
  abstract endElse(HIf node);

  void beginExpression(int precedence) {
    if (precedence < expectedPrecedence) {
      buffer.add('(');
    }
  }

  void endExpression(int precedence) {
    if (precedence < expectedPrecedence) {
      buffer.add(')');
    }
  }

  void preGenerateMethod(HGraph graph) {
    new SsaInstructionMerger(generateAtUseSite).visitGraph(graph);
    new SsaConditionMerger(generateAtUseSite,
                           logicalOperations).visitGraph(graph);
  }

  visitGraph(HGraph graph) {
    preGenerateMethod(graph);
    currentGraph = graph;
    indent++;  // We are already inside a function.
    subGraph = new SubGraph(graph.entry, graph.exit);
    beginGraph(graph);
    visitBasicBlock(graph.entry);
    if (!delayedVarDecl.isEmpty()) {
      addIndentation();
      buffer.add("var ");
      while (true) {
        buffer.add(delayedVarDecl.head);
        delayedVarDecl = delayedVarDecl.tail;
        if (delayedVarDecl.isEmpty()) break;
        buffer.add(", ");
      }
      buffer.add(";\n");
    }
    endGraph(graph);
  }

  void visitSubGraph(SubGraph newSubGraph) {
    SubGraph oldSubGraph = subGraph;
    subGraph = newSubGraph;
    visitBasicBlock(subGraph.start);
    subGraph = oldSubGraph;
  }

  bool isExpression(SubGraph limits) {
    HBasicBlock basicBlock = limits.start;
    do {
      HInstruction current = basicBlock.first;
      while (current != basicBlock.last) {
        // E.g, type guards.
        if (current.isControlFlow()) {
          return false;
        }
        current = current.next;
      }
      if (current is HGoto) {
        basicBlock = basicBlock.successors[0];
      } else if (current is HConditionalBranch) {
        if (generateAtUseSite.contains(current)) {
          // Short-circuit logical operator trickery.
          // Check the second half, which will continue into the join.
          // (The first half is [inputs[0]], the second half is [successors[0]],
          // and [successors[1]] is the join-block).
          basicBlock = basicBlock.successors[0];
        } else {
          // We allow an expression to end on an HIf (a condition expression).
          return basicBlock === limits.end;
        }
      } else {
        // Expression-incompatible control flow.
        return false;
      }
    } while (limits.contains(basicBlock));
    return true;
  }

  bool isCondition(SubGraph limits) {
    return isExpression(limits) && (limits.end.last is HConditionalBranch);
  }

  void visitExpressionGraph(SubGraph subGraph) {
    int oldState = generationState;
    generationState = STATE_FIRST_EXPRESSION;
    visitSubGraph(subGraph);
    generationState = oldState;
  }

  void visitConditionGraph(SubGraph subGraph) {
    visitExpressionGraph(subGraph);
  }

  String temporary(HInstruction instruction) {
    int id = instruction.id;
    String name = names[id];
    if (name !== null) return name;

    if (instruction is HPhi) {
      HPhi phi = instruction;
      Element element = phi.element;
      String prefix;
      if (element !== null && !element.name.isEmpty()) {
        prefix = element.name.slowToString();
      } else {
        prefix = 'v';
      }
      if (!prefixes.containsKey(prefix)) {
        prefixes[prefix] = 0;
        return newName(id, prefix);
      } else {
        return newName(id, '${prefix}_${prefixes[prefix]++}');
      }
    } else {
      String prefix = 't';
      if (!prefixes.containsKey(prefix)) prefixes[prefix] = 0;
      return newName(id, '${prefix}${prefixes[prefix]++}');
    }
  }

  bool temporaryExists(HInstruction instruction) {
    return names.containsKey(instruction.id);
  }

  String newName(int id, String name) {
    String result = JsNames.getValid(name);
    names[id] = result;
    return result;
  }

  /**
    * Only visits the arguments starting at inputs[HInvoke.ARGUMENTS_OFFSET].
    */
  void visitArguments(List<HInstruction> inputs) {
    assert(inputs.length >= HInvoke.ARGUMENTS_OFFSET);
    buffer.add('(');
    for (int i = HInvoke.ARGUMENTS_OFFSET; i < inputs.length; i++) {
      if (i != HInvoke.ARGUMENTS_OFFSET) buffer.add(', ');
      use(inputs[i], JSPrecedence.ASSIGNMENT_PRECEDENCE);
    }
    buffer.add(')');
  }



  /**
   * Whether we are currently generating expressions instead of statements.
   * This includes declarations, which are generated as expressions.
   */
  bool isGeneratingExpression() {
    return generationState != STATE_STATEMENT;
  }

  /**
   * Whether we are generating a declaration.
   */
  bool isGeneratingDeclaration() {
    return (generationState == STATE_DECLARATION ||
            generationState == STATE_FIRST_DECLARATION);
  }

  /**
   * Called before writing an expression.
   * Ensures that expressions are comma spearated.
   */
  void addExpressionSeparator() {
    if (generationState == STATE_FIRST_DECLARATION) {
      generationState = STATE_DECLARATION;
    } else if (generationState == STATE_FIRST_EXPRESSION) {
      generationState = STATE_EXPRESSION;
    } else {
      buffer.add(", ");
    }
  }

  void declareVariable(String variableName) {
    if (isGeneratingExpression()) {
      buffer.add(variableName);
      if (!isGeneratingDeclaration()) {
        delayedVarDecl = delayedVarDecl.prepend(variableName);
      }
    } else {
      buffer.add("var ");
      buffer.add(variableName);
    }
  }

  void define(HInstruction instruction) {
    String name = temporary(instruction);
    declareVariable(name);
    buffer.add(" = ");
    visit(instruction, JSPrecedence.ASSIGNMENT_PRECEDENCE);
  }

  void use(HInstruction argument, int expectedPrecedence) {
    if (isGenerateAtUseSite(argument)) {
      visit(argument, expectedPrecedence);
    } else if (argument is HIntegerCheck) {
      HIntegerCheck instruction = argument;
      use(instruction.value, expectedPrecedence);
    } else if (argument is HBoundsCheck) {
      HBoundsCheck instruction = argument;
      use(instruction.index, expectedPrecedence);
    } else if (argument is HTypeGuard) {
      HTypeGuard instruction = argument;
      use(instruction.guarded, expectedPrecedence);
    } else {
      buffer.add(temporary(argument));
    }
  }

  visit(HInstruction node, int expectedPrecedence) {
    int oldPrecedence = this.expectedPrecedence;
    this.expectedPrecedence = expectedPrecedence;
    node.accept(this);
    this.expectedPrecedence = oldPrecedence;
  }

  void continueAsBreak(LabelElement target) {
    addIndentation();
    buffer.add("break ");
    writeContinueLabel(target);
    buffer.add(";\n");
  }

  void implicitContinueAsBreak(TargetElement target) {
    addIndentation();
    buffer.add("break ");
    writeImplicitContinueLabel(target);
    buffer.add(";\n");
  }

  void implicitBreakWithLabel(TargetElement target) {
    addIndentation();
    buffer.add("break ");
    writeImplicitLabel(target);
    buffer.add(";\n");
  }

  void handleLabeledBlock(HLabeledBlockInformation labeledBlockInfo) {
    addIndentation();
    Link<Element> continueOverrides = const EmptyLink<Element>();
    // If [labeledBlockInfo.isContinue], the block is an artificial
    // block around the body of a loop with an update block, so that
    // continues of the loop can be written as breaks of the body
    // block.
    if (labeledBlockInfo.isContinue) {
      for (LabelElement label in labeledBlockInfo.labels) {
        if (label.isContinueTarget) {
          writeContinueLabel(label);
          buffer.add(':');
          continueAction[label] = continueAsBreak;
          continueOverrides = continueOverrides.prepend(label);
        }
      }
      // For handling unlabeled continues from the body of a loop.
      // TODO(lrn): Consider recording whether the target is in fact
      // a target of an unlabeled continue, and not generate this if it isn't.
      TargetElement target = labeledBlockInfo.target;
      writeImplicitContinueLabel(target);
      buffer.add(':');
      continueAction[target] = implicitContinueAsBreak;
      continueOverrides = continueOverrides.prepend(target);
    } else {
      for (LabelElement label in labeledBlockInfo.labels) {
        if (label.isBreakTarget) {
          writeLabel(label);
          buffer.add(':');
        }
      }
      TargetElement target = labeledBlockInfo.target;
      if (target.isSwitch) {
        // This is an extra block around a switch that is generated
        // as a nested if/else chain. We add an extra break target
        // so that case code can break.
        writeImplicitLabel(target);
        buffer.add(':');
        breakAction[target] = implicitBreakWithLabel;
      }
    }
    buffer.add('{\n');
    indent++;

    visitSubGraph(labeledBlockInfo.body);

    indent--;
    addIndentation();
    buffer.add('}\n');

    if (labeledBlockInfo.joinBlock !== null) {
      visitBasicBlock(labeledBlockInfo.joinBlock);
    }
    if (labeledBlockInfo.isContinue) {
      while (!continueOverrides.isEmpty()) {
        continueAction.remove(continueOverrides.head);
        continueOverrides = continueOverrides.tail;
      }
    } else {
      breakAction.remove(labeledBlockInfo.target);
    }
  }

  void emitLogicalOperation(HPhi node, String operation) {
    JSBinaryOperatorPrecedence operatorPrecedence =
        JSPrecedence.binary[operation];
    beginExpression(operatorPrecedence.precedence);
    use(node.inputs[0], operatorPrecedence.left);
    buffer.add(" $operation ");
    use(node.inputs[1], operatorPrecedence.right);
    endExpression(operatorPrecedence.precedence);
  }

  // Wraps a loop body in a block to make continues have a target to break
  // to (if necessary).
  void wrapLoopBodyForContinue(HLoopInformation info) {
    TargetElement target = info.target;
    if (target !== null && target.isContinueTarget) {
      addIndentation();
      for (LabelElement label in info.labels) {
        if (label.isContinueTarget) {
          writeContinueLabel(label);
          buffer.add(":");
          continueAction[label] = continueAsBreak;
        }
      }
      addImplicitContinueLabel();
      buffer.add(":{\n");
      continueAction[info.target] = implicitContinueAsBreak;
      indent++;
      visitSubGraph(info.body);
      indent--;
      addIndentation();
      buffer.add("}\n");
      continueAction.remove(info.target);
      for (LabelElement label in info.labels) {
        if (label.isContinueTarget) {
          continueAction.remove(label);
        }
      }
    } else {
      // Loop body contains no continues, so we don't need a break target.
      visitSubGraph(info.body);
    }
  }

  bool handleLoop(HBasicBlock node) {
    bool success = false;
    assert(node.isLoopHeader());
    HLoopInformation info = node.loopInformation;
    SubExpression condition = info.condition;
    if (isCondition(condition)) {
      switch (info.type) {
        case HLoopInformation.WHILE_LOOP:
        case HLoopInformation.FOR_IN_LOOP: {
          addIndentation();
          for (LabelElement label in info.labels) {
            writeLabel(label);
            buffer.add(":");
          }
          bool inlineUpdates =
              info.updates !== null && isExpression(info.updates);
          if (inlineUpdates) {
            buffer.add("for (; ");
            visitConditionGraph(condition);
            buffer.add("; ");
            visitExpressionGraph(info.updates);
            buffer.add(") {\n");
            indent++;
            // The body might be labeled. Ignore this when recursing on the
            // subgraph.
            // TODO(lrn): Remove this extra labeling when handling all loops
            // using subgraphs.
            HBlockInformation oldInfo = currentBlockInformation;
            currentBlockInformation = info.body.start.labeledBlockInformation;
            visitSubGraph(info.body);
            currentBlockInformation = oldInfo;

            indent--;
          } else {
            buffer.add("while (");
            visitConditionGraph(condition);
            buffer.add(") {\n");
            indent++;
            wrapLoopBodyForContinue(info);
            if (info.updates !== null) visitSubGraph(info.updates);
            indent--;
          }
          addIndentation();
          buffer.add("}\n");
          success = true;
          break;
        }
        case HLoopInformation.FOR_LOOP: {
          // TODO(lrn): Find a way to put initialization into the for.
          // It's currently handled before we reach the [HLoopInformation].
          addIndentation();
          for (LabelElement label in info.labels) {
            if (label.isTarget) {
              writeLabel(label);
              buffer.add(":");
            }
          }
          buffer.add("for(;");
          visitConditionGraph(info.condition);
          buffer.add(";");
          if (isExpression(info.updates)) {
            visitExpressionGraph(info.updates);
            buffer.add(") {\n");
            indent++;

            HBlockInformation oldInfo = currentBlockInformation;
            currentBlockInformation = info.body.start.labeledBlockInformation;
            visitSubGraph(info.body);
            currentBlockInformation = oldInfo;

            indent--;
            addIndentation();
            buffer.add("}\n");
          } else {
            buffer.add(") {\n");
            indent++;
            wrapLoopBodyForContinue(info);
            visitSubGraph(info.updates);
            indent--;
            buffer.add("}\n");
          }
          success = true;
          break;
        }
        case HLoopInformation.DO_WHILE_LOOP:
          // Currently unhandled.
        default:
      }
    }
    return success;
  }

  void visitBasicBlock(HBasicBlock node) {
    // Abort traversal if we are leaving the currently active sub-graph.
    if (!subGraph.contains(node)) return;

    // If this node has special behavior attached, handle it.
    // If we reach here again while handling the attached information,
    // e.g., because we call visitSubGraph on a subgraph starting here,
    // don't handle it again.
    if (node.hasLabeledBlockInformation() &&
        node.labeledBlockInformation !== currentBlockInformation) {
      HBlockInformation oldBlockInformation = currentBlockInformation;
      currentBlockInformation = node.labeledBlockInformation;
      handleLabeledBlock(currentBlockInformation);
      currentBlockInformation = oldBlockInformation;
      return;
    }

    if (node.isLoopHeader() &&
        node.loopInformation !== currentBlockInformation) {
      HBlockInformation oldBlockInformation = currentBlockInformation;
      currentBlockInformation = node.loopInformation;
      bool prettyLoop = handleLoop(node);
      currentBlockInformation = oldBlockInformation;
      if (prettyLoop) {
        visitBasicBlock(node.loopInformation.joinBlock);
        return;
      }
      beginLoop(node);
    }

    iterateBasicBlock(node);
  }

  void iterateBasicBlock(HBasicBlock node) {
    currentBlock = node;
    HInstruction instruction = node.first;
    while (instruction != null) {
      if (instruction === node.last) {
        for (HBasicBlock successor in node.successors) {
          int index = successor.predecessors.indexOf(node);
          successor.forEachPhi((HPhi phi) {
            bool isLogicalOperation = logicalOperations.containsKey(phi);
            // In case the phi is being generated by another
            // instruction.
            if (isLogicalOperation && isGenerateAtUseSite(phi)) return;
            if (isGeneratingExpression()) {
              addExpressionSeparator();
            } else {
              addIndentation();
            }
            if (!temporaryExists(phi)) {
              declareVariable(temporary(phi));
            } else {
              buffer.add(temporary(phi));
            }
            buffer.add(" = ");
            if (isLogicalOperation) {
              emitLogicalOperation(phi, logicalOperations[phi]);
            } else {
              use(phi.inputs[index], JSPrecedence.ASSIGNMENT_PRECEDENCE);
            }
            if (!isGeneratingExpression()) {
              buffer.add(';\n');
            }
          });
        }
      }

      if (instruction is HGoto || instruction is HExit || instruction is HTry) {
        visit(instruction, JSPrecedence.STATEMENT_PRECEDENCE);
        return;
      } else if (!isGenerateAtUseSite(instruction)) {
        if (instruction is !HIf && instruction is !HTypeGuard &&
            !isGeneratingExpression()) {
          addIndentation();
        }
        if (isGeneratingExpression()) {
          addExpressionSeparator();
        }
        if (instruction.usedBy.isEmpty()
            || instruction is HTypeGuard
            || instruction is HCheck) {
          visit(instruction, JSPrecedence.STATEMENT_PRECEDENCE);
        } else {
          define(instruction);
        }
        // Control flow instructions know how to handle ';'.
        if (instruction is !HControlFlow && instruction is !HTypeGuard &&
            !isGeneratingExpression()) {
          buffer.add(';\n');
        }
      } else if (instruction is HIf) {
        HIf hif = instruction;
        // The "if" is implementing part of a logical expression.
        // Skip directly forward to to its latest successor, since everything
        // in-between must also be generateAtUseSite.
        assert(hif.trueBranch.id < hif.falseBranch.id);
        visitBasicBlock(hif.falseBranch);
        return;
      }
      instruction = instruction.next;
    }
  }

  visitInvokeBinary(HInvokeBinary node, String op) {
    if (node.builtin) {
      JSBinaryOperatorPrecedence operatorPrecedences = JSPrecedence.binary[op];
      beginExpression(operatorPrecedences.precedence);
      use(node.left, operatorPrecedences.left);
      buffer.add(' $op ');
      use(node.right, operatorPrecedences.right);
      endExpression(operatorPrecedences.precedence);
    } else {
      visitInvokeStatic(node);
    }
  }

  visitInvokeUnary(HInvokeUnary node, String op) {
    if (node.builtin) {
      beginExpression(JSPrecedence.PREFIX_PRECEDENCE);
      buffer.add('$op');
      use(node.operand, JSPrecedence.PREFIX_PRECEDENCE);
      endExpression(JSPrecedence.PREFIX_PRECEDENCE);
    } else {
      visitInvokeStatic(node);
    }
  }

  visitEquals(HEquals node) {
    if (node.builtin) {
      beginExpression(JSPrecedence.EQUALITY_PRECEDENCE);
      use(node.left, JSPrecedence.EQUALITY_PRECEDENCE);
      buffer.add(' === ');
      use(node.right, JSPrecedence.RELATIONAL_PRECEDENCE);
      endExpression(JSPrecedence.EQUALITY_PRECEDENCE);
    } else if (node.element === equalsNullElement) {
      beginExpression(JSPrecedence.CALL_PRECEDENCE);
      use(node.target, JSPrecedence.CALL_PRECEDENCE);
      buffer.add('(');
      use(node.left, JSPrecedence.ASSIGNMENT_PRECEDENCE);
      buffer.add(')');
      endExpression(JSPrecedence.CALL_PRECEDENCE);
    } else {
      visitInvokeStatic(node);
    }
  }

  visitAdd(HAdd node)               => visitInvokeBinary(node, '+');
  visitDivide(HDivide node)         => visitInvokeBinary(node, '/');
  visitMultiply(HMultiply node)     => visitInvokeBinary(node, '*');
  visitSubtract(HSubtract node)     => visitInvokeBinary(node, '-');
  // Truncating divide does not have a JS equivalent.
  visitTruncatingDivide(HTruncatingDivide node) => visitInvokeStatic(node);
  // Modulo cannot be mapped to the native operator (different semantics).
  visitModulo(HModulo node)                     => visitInvokeStatic(node);

  visitBitAnd(HBitAnd node)         => visitInvokeBinary(node, '&');
  visitBitNot(HBitNot node)         => visitInvokeUnary(node, '~');
  visitBitOr(HBitOr node)           => visitInvokeBinary(node, '|');
  visitBitXor(HBitXor node)         => visitInvokeBinary(node, '^');

  // We need to check if the left operand is negative in order to use
  // the native operator.
  visitShiftRight(HShiftRight node) => visitInvokeStatic(node);

  // Shift left cannot be mapped to the native operator (different semantics).
  visitShiftLeft(HShiftLeft node)   => visitInvokeStatic(node);

  visitNegate(HNegate node)         => visitInvokeUnary(node, '-');

  visitIdentity(HIdentity node)         => visitInvokeBinary(node, '===');
  visitLess(HLess node)                 => visitInvokeBinary(node, '<');
  visitLessEqual(HLessEqual node)       => visitInvokeBinary(node, '<=');
  visitGreater(HGreater node)           => visitInvokeBinary(node, '>');
  visitGreaterEqual(HGreaterEqual node) => visitInvokeBinary(node, '>=');

  visitBoolify(HBoolify node) {
    beginExpression(JSPrecedence.EQUALITY_PRECEDENCE);
    assert(node.inputs.length == 1);
    use(node.inputs[0], JSPrecedence.EQUALITY_PRECEDENCE);
    buffer.add(' === true');
    endExpression(JSPrecedence.EQUALITY_PRECEDENCE);
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
    if (dominated.length > 2) unreachable();
    if (dominated.length == 2 && currentBlock !== currentGraph.entry) {
      unreachable();
    }
    assert(dominated[0] == currentBlock.successors[0]);
    visitBasicBlock(dominated[0]);
  }

  // Used to write the name of labels.
  void writeLabel(LabelElement label) {
    buffer.add('\$${label.labelName}\$${label.target.nestingLevel}');
  }

  void writeImplicitLabel(TargetElement target) {
    buffer.add('\$${target.nestingLevel}');
  }

  // We sometimes handle continue targets differently from break targets,
  // so we have special continue-only labels.
  void writeContinueLabel(LabelElement label) {
    buffer.add('c\$${label.labelName}\$${label.target.nestingLevel}');
  }

  void writeImplicitContinueLabel(TargetElement target) {
    buffer.add('c\$${target.nestingLevel}');
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
        addIndentation();
        buffer.add("break ");
        writeLabel(label);
        buffer.add(";\n");
      }
    } else {
      TargetElement target = node.target;
      if (!tryCallAction(breakAction, target)) {
        addIndentation();
        buffer.add("break;\n");
      }
    }
  }

  visitContinue(HContinue node) {
    assert(currentBlock.successors.length == 1);
    if (node.label !== null) {
      LabelElement label = node.label;
      if (!tryCallAction(continueAction, label)) {
        addIndentation();
        buffer.add("continue ");
        writeLabel(label);
        buffer.add(";\n");
      }
    } else {
      TargetElement target = node.target;
      if (!tryCallAction(continueAction, target)) {
        addIndentation();
        buffer.add("continue;\n");
      }
    }
  }

  visitTry(HTry node) {
    addIndentation();
    buffer.add('try {\n');
    indent++;
    List<HBasicBlock> successors = node.block.successors;
    visitBasicBlock(successors[0]);
    indent--;

    if (node.finallyBlock != successors[1]) {
      // Printing the catch part.
      addIndentation();
      String name = temporary(node.exception);
      parameterNames[node.exception.element] = name;
      buffer.add('} catch ($name) {\n');
      indent++;
      visitBasicBlock(successors[1]);
      parameterNames.remove(node.exception.element);
      indent--;
    }

    if (node.finallyBlock != null) {
      addIndentation();
      buffer.add('} finally {\n');
      indent++;
      visitBasicBlock(node.finallyBlock);
      indent--;
    }
    addIndentation();
    buffer.add('}\n');

    visitBasicBlock(node.joinBlock);
  }

  visitIf(HIf node) {
    HInstruction condition = node.inputs[0];
    int preVisitedBlocks = 0;
    List<HBasicBlock> dominated = node.block.dominatedBlocks;
    HIfBlockInformation info = node.blockInformation;
    if (condition.isConstant()) {
      HConstant constant = condition;
      if (constant.constant.isTrue()) {
        visitSubGraph(info.thenGraph);
      } else if (node.hasElse) {
        visitSubGraph(info.elseGraph);
      }
      // We ignore the other branch, even if it isn't visited.
      preVisitedBlocks = node.hasElse ? 2 : 1;
    } else {
      startIf(node);
      assert(!isGenerateAtUseSite(node));
      startThen(node);
      assert(node.thenBlock === dominated[0]);
      visitSubGraph(info.thenGraph);
      preVisitedBlocks++;
      endThen(node);
      if (node.hasElse) {
        startElse(node);
        assert(node.elseBlock === dominated[1]);
        visitSubGraph(info.elseGraph);
        preVisitedBlocks++;
        endElse(node);
      }
      endIf(node);
    }
    if (info.joinBlock !== null && info.joinBlock.dominator !== node.block) {
      // The join block is dominated by a block in one of the branches.
      // The subgraph traversal never reached it, so we visit it here
      // instead.
      visitBasicBlock(info.joinBlock);
    }

    // Visit all the dominated blocks that are not part of the then or else
    // branches, and is not the join block.
    // Depending on how the then/else branches terminate
    // (e.g., return/throw/break) there can be any number of these.
    int dominatedCount = dominated.length;
    for (int i = preVisitedBlocks; i < dominatedCount; i++) {
      HBasicBlock dominatedBlock = dominated[i];
      assert(dominatedBlock.dominator === node.block);
      visitBasicBlock(dominatedBlock);
    }
  }

  visitInvokeDynamicMethod(HInvokeDynamicMethod node) {
    beginExpression(JSPrecedence.CALL_PRECEDENCE);
    use(node.receiver, JSPrecedence.MEMBER_PRECEDENCE);
    buffer.add('.');
    // Avoid adding the generative constructor name to the list of
    // seen selectors.
    if (node.inputs[0] is HForeignNew) {
      HForeignNew foreignNew = node.inputs[0];
      // Remove 'this' from the number of arguments.
      int argumentCount = node.inputs.length - 1;

      // TODO(ahe): The constructor name was statically resolved in
      // SsaBuilder.buildFactory. Is there a cleaner way to do this?
      node.name.printOn(buffer);
      visitArguments(node.inputs);
    } else {
      buffer.add(compiler.namer.instanceMethodInvocationName(
          currentLibrary, node.name, node.selector));
      visitArguments(node.inputs);
      compiler.registerDynamicInvocation(node.name, node.selector);
    }
    endExpression(JSPrecedence.CALL_PRECEDENCE);
  }

  visitInvokeDynamicSetter(HInvokeDynamicSetter node) {
    beginExpression(JSPrecedence.CALL_PRECEDENCE);
    use(node.receiver, JSPrecedence.MEMBER_PRECEDENCE);
    buffer.add('.');
    buffer.add(compiler.namer.setterName(currentLibrary, node.name));
    visitArguments(node.inputs);
    compiler.registerDynamicSetter(node.name);
    endExpression(JSPrecedence.CALL_PRECEDENCE);
  }

  visitInvokeDynamicGetter(HInvokeDynamicGetter node) {
    beginExpression(JSPrecedence.CALL_PRECEDENCE);
    use(node.receiver, JSPrecedence.MEMBER_PRECEDENCE);
    buffer.add('.');
    buffer.add(compiler.namer.getterName(currentLibrary, node.name));
    visitArguments(node.inputs);
    compiler.registerDynamicGetter(node.name);
    endExpression(JSPrecedence.CALL_PRECEDENCE);
  }

  visitInvokeClosure(HInvokeClosure node) {
    beginExpression(JSPrecedence.CALL_PRECEDENCE);
    use(node.receiver, JSPrecedence.MEMBER_PRECEDENCE);
    buffer.add('.');
    buffer.add(compiler.namer.closureInvocationName(node.selector));
    visitArguments(node.inputs);
    // TODO(floitsch): we should have a separate list for closure invocations.
    compiler.registerDynamicInvocation(Namer.CLOSURE_INVOCATION_NAME,
                                       node.selector);
    endExpression(JSPrecedence.CALL_PRECEDENCE);
  }

  visitInvokeStatic(HInvokeStatic node) {
    beginExpression(JSPrecedence.CALL_PRECEDENCE);
    use(node.target, JSPrecedence.CALL_PRECEDENCE);
    visitArguments(node.inputs);
    endExpression(JSPrecedence.CALL_PRECEDENCE);
  }

  visitInvokeSuper(HInvokeSuper node) {
    beginExpression(JSPrecedence.CALL_PRECEDENCE);
    Element superMethod = node.element;
    Element superClass = superMethod.enclosingElement;
    // Remove the element and 'this'.
    int argumentCount = node.inputs.length - 2;
    String className = compiler.namer.isolatePropertyAccess(superClass);
    String methodName;
    if (superMethod.kind == ElementKind.FUNCTION ||
        superMethod.kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
      methodName = compiler.namer.instanceMethodName(
          currentLibrary, superMethod.name, argumentCount);
    } else {
      methodName = compiler.namer.getterName(currentLibrary, superMethod.name);
      // We need to register the name to ensure that the emitter
      // generates the necessary getter.
      // TODO(ahe): This is not optimal for tree-shaking, but we lack
      // API to register the precise information. In this case, the
      // enclosingElement of superMethod needs the getter, no other
      // class (not even its subclasses).
      compiler.registerDynamicGetter(superMethod.name);
    }
    buffer.add('$className.prototype.$methodName.call');
    visitArguments(node.inputs);
    endExpression(JSPrecedence.CALL_PRECEDENCE);
    compiler.registerStaticUse(superMethod);
  }

  visitFieldGet(HFieldGet node) {
    String name = JsNames.getValid(node.element.name.slowToString());
    if (node.receiver !== null) {
      beginExpression(JSPrecedence.MEMBER_PRECEDENCE);
      use(node.receiver, JSPrecedence.MEMBER_PRECEDENCE);
      buffer.add('.');
      buffer.add(name);
      beginExpression(JSPrecedence.MEMBER_PRECEDENCE);
    } else {
      buffer.add(name);
    }
  }

  visitFieldSet(HFieldSet node) {
    // This method may introduce variable declarations in the JS code.
    // If we are generating an expression, those variable declarations
    // must be delayed until later.
    bool delayDeclaration = false;
    String name = JsNames.getValid(node.element.name.slowToString());
    if (node.receiver !== null) {
      beginExpression(JSPrecedence.ASSIGNMENT_PRECEDENCE);
      use(node.receiver, JSPrecedence.MEMBER_PRECEDENCE);
      buffer.add('.');
      buffer.add(name);
    } else {
      // TODO(ngeoffray): Remove the 'var' once we don't globally box
      // variables used in a try/catch.
      declareVariable(name);
    }
    if (delayDeclaration) delayedVarDecl = delayedVarDecl.prepend(name);
    buffer.add(' = ');
    use(node.value, JSPrecedence.ASSIGNMENT_PRECEDENCE);
    if (node.receiver !== null) {
      endExpression(JSPrecedence.ASSIGNMENT_PRECEDENCE);
    }
  }

  visitForeign(HForeign node) {
    String code = node.code.slowToString();
    List<HInstruction> inputs = node.inputs;
    List<String> parts = code.split('#');
    if (parts.length != inputs.length + 1) {
      compiler.internalError(
          'Wrong number of arguments for JS', instruction: node);
    }
    beginExpression(JSPrecedence.EXPRESSION_PRECEDENCE);
    buffer.add(parts[0]);
    for (int i = 0; i < inputs.length; i++) {
      use(inputs[i], JSPrecedence.EXPRESSION_PRECEDENCE);
      buffer.add(parts[i + 1]);
    }
    endExpression(JSPrecedence.EXPRESSION_PRECEDENCE);
  }

  visitForeignNew(HForeignNew node) {
    String jsClassReference = compiler.namer.isolateAccess(node.element);
    beginExpression(JSPrecedence.MEMBER_PRECEDENCE);
    buffer.add('new $jsClassReference(');
    // We can't use 'visitArguments', since our arguments start at input[0].
    List<HInstruction> inputs = node.inputs;
    for (int i = 0; i < inputs.length; i++) {
      if (i != 0) buffer.add(', ');
      use(inputs[i], JSPrecedence.ASSIGNMENT_PRECEDENCE);
    }
    buffer.add(')');
    endExpression(JSPrecedence.MEMBER_PRECEDENCE);
  }

  visitConstant(HConstant node) {
    assert(isGenerateAtUseSite(node));
    // TODO(floitsch): the compile-time constant handler and the codegen
    // need to work together to avoid the parenthesis. See r4928 for an
    // implementation that still dealt with precedence.
    ConstantHandler handler = compiler.constantHandler;
    String name = handler.getNameForConstant(node.constant);
    if (name === null) {
      assert(!node.constant.isObject());
      if (node.constant.isNum()
          && expectedPrecedence == JSPrecedence.MEMBER_PRECEDENCE) {
        buffer.add('(');
        handler.writeConstant(buffer, node.constant);
        buffer.add(')');
      } else {
        handler.writeConstant(buffer, node.constant);
      }
    } else {
      buffer.add(compiler.namer.CURRENT_ISOLATE);
      buffer.add(".");
      buffer.add(name);
    }
  }

  visitLoopBranch(HLoopBranch node) {
    if (subGraph !== null && node.block == subGraph.end) {
      // We are generating code for a loop condition.
      // If doing this as part of a SubGraph traversal, the
      // calling code will handle the control flow logic.

      // Currently we only traverse condition subgraphs as expressions.
      assert(isGeneratingExpression());
      use(node.inputs[0], JSPrecedence.EXPRESSION_PRECEDENCE);
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
    beginExpression(JSPrecedence.PREFIX_PRECEDENCE);
    buffer.add('!');
    use(node.inputs[0], JSPrecedence.PREFIX_PRECEDENCE);
    endExpression(JSPrecedence.PREFIX_PRECEDENCE);
  }

  visitParameterValue(HParameterValue node) {
    assert(isGenerateAtUseSite(node));
    buffer.add(parameterNames[node.element]);
  }

  visitPhi(HPhi node) {
    String operation = logicalOperations[node];
    if (operation !== null) {
      emitLogicalOperation(node, operation);
    } else {
      buffer.add('${temporary(node)}');
    }
  }

  visitReturn(HReturn node) {
    assert(node.inputs.length == 1);
    HInstruction input = node.inputs[0];
    if (input.isConstantNull()) {
      buffer.add('return;\n');
    } else {
      buffer.add('return ');
      use(node.inputs[0], JSPrecedence.EXPRESSION_PRECEDENCE);
      buffer.add(';\n');
    }
  }

  visitThis(HThis node) {
    buffer.add('this');
  }

  visitThrow(HThrow node) {
    if (node.isRethrow) {
      buffer.add('throw ');
      use(node.inputs[0], JSPrecedence.EXPRESSION_PRECEDENCE);
    } else {
      generateThrowWithHelper('captureStackTrace', node.inputs[0]);
    }
    buffer.add(';\n');
  }

  visitBoundsCheck(HBoundsCheck node) {
    buffer.add('if (');
    use(node.index, JSPrecedence.RELATIONAL_PRECEDENCE);
    buffer.add(' < 0 || ');
    use(node.index, JSPrecedence.RELATIONAL_PRECEDENCE);
    buffer.add(' >= ');
    use(node.length, JSPrecedence.SHIFT_PRECEDENCE);
    buffer.add(") ");
    generateThrowWithHelper('ioore', node.index);
  }

  visitIntegerCheck(HIntegerCheck node) {
    buffer.add('if (');
    use(node.value, JSPrecedence.EQUALITY_PRECEDENCE);
    buffer.add(' !== (');
    use(node.value, JSPrecedence.BITWISE_OR_PRECEDENCE);
    buffer.add(" | 0)) ");
    generateThrowWithHelper('iae', node.value);
  }

  void generateThrowWithHelper(String helperName, HInstruction argument) {
    Element helper = compiler.findHelper(new SourceString(helperName));
    compiler.registerStaticUse(helper);
    buffer.add('throw ');
    beginExpression(JSPrecedence.EXPRESSION_PRECEDENCE);
    beginExpression(JSPrecedence.CALL_PRECEDENCE);
    buffer.add(compiler.namer.isolateAccess(helper));
    visitArguments([null, argument]);
    endExpression(JSPrecedence.CALL_PRECEDENCE);
    endExpression(JSPrecedence.EXPRESSION_PRECEDENCE);
  }

  void addIndentation() {
    for (int i = 0; i < indent; i++) {
      buffer.add('  ');
    }
  }

  void visitStatic(HStatic node) {
    compiler.registerStaticUse(node.element);
    buffer.add(compiler.namer.isolateAccess(node.element));
  }

  void visitStaticStore(HStaticStore node) {
    compiler.registerStaticUse(node.element);
    beginExpression(JSPrecedence.ASSIGNMENT_PRECEDENCE);
    buffer.add(compiler.namer.isolateAccess(node.element));
    buffer.add(' = ');
    use(node.inputs[0], JSPrecedence.ASSIGNMENT_PRECEDENCE);
    endExpression(JSPrecedence.ASSIGNMENT_PRECEDENCE);
  }

  void visitLiteralList(HLiteralList node) {
    if (node.isConst) {
      // TODO(floitsch): Remove this when CTC handles arrays.
      SourceString name = new SourceString('makeLiteralListConst');
      Element helper = compiler.findHelper(name);
      compiler.registerStaticUse(helper);
      beginExpression(JSPrecedence.CALL_PRECEDENCE);
      buffer.add(compiler.namer.isolateAccess(helper));
      buffer.add('(');
      generateArrayLiteral(node);
      buffer.add(')');
      endExpression(JSPrecedence.CALL_PRECEDENCE);
    } else {
      generateArrayLiteral(node);
    }
  }

  void generateArrayLiteral(HLiteralList node) {
    buffer.add('[');
    int len = node.inputs.length;
    for (int i = 0; i < len; i++) {
      if (i != 0) buffer.add(', ');
      use(node.inputs[i], JSPrecedence.ASSIGNMENT_PRECEDENCE);
    }
    buffer.add(']');
  }

  void visitIndex(HIndex node) {
    if (node.builtin) {
      beginExpression(JSPrecedence.MEMBER_PRECEDENCE);
      use(node.inputs[1], JSPrecedence.MEMBER_PRECEDENCE);
      buffer.add('[');
      use(node.inputs[2], JSPrecedence.EXPRESSION_PRECEDENCE);
      buffer.add(']');
      endExpression(JSPrecedence.MEMBER_PRECEDENCE);
    } else {
      visitInvokeStatic(node);
    }
  }

  void visitIndexAssign(HIndexAssign node) {
    if (node.builtin) {
      beginExpression(JSPrecedence.ASSIGNMENT_PRECEDENCE);
      use(node.inputs[1], JSPrecedence.MEMBER_PRECEDENCE);
      buffer.add('[');
      use(node.inputs[2], JSPrecedence.EXPRESSION_PRECEDENCE);
      buffer.add('] = ');
      use(node.inputs[3], JSPrecedence.ASSIGNMENT_PRECEDENCE);
      endExpression(JSPrecedence.ASSIGNMENT_PRECEDENCE);
    } else {
      visitInvokeStatic(node);
    }
  }

  void visitInvokeInterceptor(HInvokeInterceptor node) {
    if (node.builtinJsName != null) {
      beginExpression(JSPrecedence.CALL_PRECEDENCE);
      use(node.inputs[1], JSPrecedence.MEMBER_PRECEDENCE);
      buffer.add('.');
      buffer.add(node.builtinJsName);
      if (node.getter) return;
      buffer.add('(');
      for (int i = 2; i < node.inputs.length; i++) {
        if (i != 2) buffer.add(', ');
        use(node.inputs[i], JSPrecedence.ASSIGNMENT_PRECEDENCE);
      }
      buffer.add(")");
      endExpression(JSPrecedence.CALL_PRECEDENCE);
    } else {
      return visitInvokeStatic(node);
    }
  }

  void checkInt(HInstruction input, String cmp) {
    beginExpression(JSPrecedence.EQUALITY_PRECEDENCE);
    use(input, JSPrecedence.EQUALITY_PRECEDENCE);
    buffer.add(' $cmp (');
    use(input, JSPrecedence.BITWISE_OR_PRECEDENCE);
    buffer.add(' | 0)');
    endExpression(JSPrecedence.EQUALITY_PRECEDENCE);
  }

  void checkNum(HInstruction input, String cmp) {
    beginExpression(JSPrecedence.EQUALITY_PRECEDENCE);
    buffer.add('typeof ');
    use(input, JSPrecedence.PREFIX_PRECEDENCE);
    buffer.add(" $cmp 'number'");
    endExpression(JSPrecedence.EQUALITY_PRECEDENCE);
  }

  void checkDouble(HInstruction input, String cmp) {
    checkNum(input, cmp);
  }

  void checkString(HInstruction input, String cmp) {
    beginExpression(JSPrecedence.EQUALITY_PRECEDENCE);
    buffer.add('typeof ');
    use(input, JSPrecedence.PREFIX_PRECEDENCE);
    buffer.add(" $cmp 'string'");
    endExpression(JSPrecedence.EQUALITY_PRECEDENCE);
  }

  void checkBool(HInstruction input, String cmp) {
    beginExpression(JSPrecedence.EQUALITY_PRECEDENCE);
    buffer.add('typeof ');
    use(input, JSPrecedence.PREFIX_PRECEDENCE);
    buffer.add(" $cmp 'boolean'");
    endExpression(JSPrecedence.EQUALITY_PRECEDENCE);
  }

  void checkObject(HInstruction input, String cmp) {
    beginExpression(JSPrecedence.EQUALITY_PRECEDENCE);
    buffer.add('typeof ');
    use(input, JSPrecedence.PREFIX_PRECEDENCE);
    buffer.add(" $cmp 'object'");
    endExpression(JSPrecedence.EQUALITY_PRECEDENCE);
  }

  void checkArray(HInstruction input, String cmp) {
    beginExpression(JSPrecedence.EQUALITY_PRECEDENCE);
    use(input, JSPrecedence.MEMBER_PRECEDENCE);
    buffer.add('.constructor $cmp Array');
    endExpression(JSPrecedence.EQUALITY_PRECEDENCE);
  }

  void checkNull(HInstruction input) {
    beginExpression(JSPrecedence.EQUALITY_PRECEDENCE);
    use(input, JSPrecedence.EQUALITY_PRECEDENCE);
    buffer.add(" === (void 0)");
    endExpression(JSPrecedence.EQUALITY_PRECEDENCE);
  }

  void checkFunction(HInstruction input, Element element) {
    beginExpression(JSPrecedence.LOGICAL_OR_PRECEDENCE);
    beginExpression(JSPrecedence.EQUALITY_PRECEDENCE);
    buffer.add('typeof ');
    use(input, JSPrecedence.PREFIX_PRECEDENCE);
    buffer.add(" === 'function'");
    endExpression(JSPrecedence.EQUALITY_PRECEDENCE);
    buffer.add(" || ");
    beginExpression(JSPrecedence.LOGICAL_AND_PRECEDENCE);
    checkObject(input, '===');
    buffer.add(" && ");
    checkType(input, element);
    endExpression(JSPrecedence.LOGICAL_AND_PRECEDENCE);
    endExpression(JSPrecedence.LOGICAL_OR_PRECEDENCE);
  }

  void checkType(HInstruction input, Element element) {
    bool requiresNativeIsCheck =
        compiler.emitter.nativeEmitter.requiresNativeIsCheck(element);
    if (!requiresNativeIsCheck) buffer.add('!!');
    use(input, JSPrecedence.MEMBER_PRECEDENCE);
    buffer.add('.');
    buffer.add(compiler.namer.operatorIs(element));
    if (requiresNativeIsCheck) buffer.add('()');
  }

  void handleStringSupertypeCheck(HInstruction input, Element element) {
    // Make sure List and String don't share supertypes, otherwise we
    // would need to check for List too.
    assert(element !== compiler.listClass
           && !Elements.isListSupertype(element, compiler));
    beginExpression(JSPrecedence.LOGICAL_OR_PRECEDENCE);
    checkString(input, '===');
    buffer.add(' || ');
    beginExpression(JSPrecedence.LOGICAL_AND_PRECEDENCE);
    checkObject(input, '===');
    buffer.add(' && ');
    checkType(input, element);
    endExpression(JSPrecedence.LOGICAL_AND_PRECEDENCE);
    endExpression(JSPrecedence.LOGICAL_OR_PRECEDENCE);
  }

  void handleListOrSupertypeCheck(HInstruction input, Element element) {
    // Make sure List and String don't share supertypes, otherwise we
    // would need to check for String too.
    assert(element !== compiler.stringClass
           && !Elements.isStringSupertype(element, compiler));
    beginExpression(JSPrecedence.LOGICAL_AND_PRECEDENCE);
    checkObject(input, '===');
    buffer.add(' && (');
    beginExpression(JSPrecedence.LOGICAL_OR_PRECEDENCE);
    checkArray(input, '===');
    buffer.add(' || ');
    checkType(input, element);
    buffer.add(')');
    endExpression(JSPrecedence.LOGICAL_OR_PRECEDENCE);
    endExpression(JSPrecedence.LOGICAL_AND_PRECEDENCE);
  }

  void visitIs(HIs node) {
    Element element = node.typeExpression;
    if (element.kind === ElementKind.TYPE_VARIABLE) {
      compiler.unimplemented("visitIs for type variables");
    }
    compiler.registerIsCheck(element);
    LibraryElement coreLibrary = compiler.coreLibrary;
    ClassElement objectClass = coreLibrary.find(const SourceString('Object'));
    HInstruction input = node.expression;
    if (node.nullOk) {
      beginExpression(JSPrecedence.LOGICAL_OR_PRECEDENCE);
      checkNull(input);
      buffer.add(' || ');
    }

    if (element === objectClass || element === compiler.dynamicClass) {
      // The constant folder also does this optimization, but we make
      // it safe by assuming it may have not run.
      buffer.add('true');
    } else if (element == compiler.stringClass) {
      checkString(input, '===');
    } else if (element == compiler.doubleClass) {
      checkDouble(input, '===');
    } else if (element == compiler.numClass) {
      checkNum(input, '===');
    } else if (element == compiler.boolClass) {
      checkBool(input, '===');
    } else if (element == compiler.functionClass) {
      checkFunction(input, element);
    } else if (element == compiler.intClass) {
      beginExpression(JSPrecedence.LOGICAL_AND_PRECEDENCE);
      checkNum(input, '===');
      buffer.add(' && ');
      checkInt(input, '===');
      endExpression(JSPrecedence.LOGICAL_AND_PRECEDENCE);
    } else if (Elements.isStringSupertype(element, compiler)) {
        handleStringSupertypeCheck(input, element);
    } else if (element === compiler.listClass
               || Elements.isListSupertype(element, compiler)) {
      handleListOrSupertypeCheck(input, element);
    } else {
      beginExpression(JSPrecedence.LOGICAL_AND_PRECEDENCE);
      checkObject(input, '===');
      buffer.add(' && ');
      checkType(input, element);
      endExpression(JSPrecedence.LOGICAL_AND_PRECEDENCE);
    }

    if (node.nullOk) {
      endExpression(JSPrecedence.LOGICAL_OR_PRECEDENCE);
    }
  }
}

class SsaOptimizedCodeGenerator extends SsaCodeGenerator {
  SsaOptimizedCodeGenerator(compiler, work, parameters, parameterNames)
    : super(compiler, work, parameters, parameterNames);

  void beginGraph(HGraph graph) {}
  void endGraph(HGraph graph) {}

  void bailout(HTypeGuard guard, String reason) {
    HInstruction input = guard.guarded;
    Namer namer = compiler.namer;
    Element element = work.element;
    buffer.add('return ');
    if (element.isInstanceMember()) {
      // TODO(ngeoffray): This does not work in case we come from a
      // super call. We must make bailout names unique.
      buffer.add('this.${namer.getBailoutName(element)}');
    } else {
      buffer.add(namer.isolateBailoutAccess(element));
    }
    int parametersCount = parameterNames.length;
    buffer.add('($parameters');
    if (parametersCount != 0) buffer.add(', ');
    if (guard.guarded is !HParameterValue) {
      buffer.add('${guard.state}');
      bool first = true;
      // TODO(ngeoffray): if the bailout method takes more arguments,
      // fill the remaining arguments with undefined.
      // TODO(ngeoffray): try to put a variable at a deterministic
      // location, so that multiple bailout calls put the variable at
      // the same parameter index.
      for (int i = 0; i < guard.inputs.length; i++) {
        buffer.add(', ');
        use(guard.inputs[i], JSPrecedence.ASSIGNMENT_PRECEDENCE);
      }
    } else {
      assert(guard.guarded is HParameterValue);
      buffer.add(' 0');
    }
    buffer.add(')');
  }

  void visitTypeGuard(HTypeGuard node) {
    addIndentation();
    HInstruction input = node.guarded;
    assert(!isGenerateAtUseSite(input) || input.isCodeMotionInvariant());
    if (node.isInteger()) {
      buffer.add('if (');
      checkInt(input, '!==');
      buffer.add(') ');
      bailout(node, 'Not an integer');
    } else if (node.isNumber()) {
      buffer.add('if (');
      checkNum(input, '!==');
      buffer.add(') ');
      bailout(node, 'Not a number');
    } else if (node.isBoolean()) {
      buffer.add('if (');
      checkBool(input, '!==');
      buffer.add(') ');
      bailout(node, 'Not a boolean');
    } else if (node.isString()) {
      buffer.add('if (');
      checkString(input, '!==');
      buffer.add(') ');
      bailout(node, 'Not a string');
    } else if (node.isArray()) {
      buffer.add('if (');
      checkObject(input, '!==');
      buffer.add('||');
      checkArray(input, '!==');
      buffer.add(') ');
      bailout(node, 'Not an array');
    } else if (node.isStringOrArray()) {
      buffer.add('if (');
      checkString(input, '!==');
      buffer.add(' && (');
      checkObject(input, '!==');
      buffer.add('||');
      checkArray(input, '!==');
      buffer.add(')) ');
      bailout(node, 'Not a string or array');
    } else {
      unreachable();
    }
    buffer.add(';\n');
  }

  void beginLoop(HBasicBlock block) {
    addIndentation();
    for (LabelElement label in block.loopInformation.labels) {
      writeLabel(label);
      buffer.add(":");
    }
    buffer.add('while (true) {\n');
    indent++;
  }

  void endLoop(HBasicBlock block) {
    indent--;
    addIndentation();
    buffer.add('}\n');  // Close 'while' loop.
  }

  void handleLoopCondition(HLoopBranch node) {
    buffer.add('if (!');
    use(node.inputs[0], JSPrecedence.PREFIX_PRECEDENCE);
    buffer.add(') break;\n');
  }

  void startIf(HIf node) {
  }

  void endIf(HIf node) {
    indent--;
    addIndentation();
    buffer.add('}\n');
  }

  void startThen(HIf node) {
    addIndentation();
    buffer.add('if (');
    use(node.inputs[0], JSPrecedence.EXPRESSION_PRECEDENCE);
    buffer.add(') {\n');
    indent++;
  }

  void endThen(HIf node) {
  }

  void startElse(HIf node) {
    indent--;
    addIndentation();
    buffer.add('} else {\n');
    indent++;
  }

  void endElse(HIf node) {
  }
}

class SsaUnoptimizedCodeGenerator extends SsaCodeGenerator {

  final StringBuffer setup;
  final List<String> labels;
  int labelId = 0;
  int maxBailoutParameters = 0;

  SsaUnoptimizedCodeGenerator(compiler, work, parameters, parameterNames)
    : super(compiler, work, parameters, parameterNames),
      setup = new StringBuffer(),
      labels = <String>[];

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

  void beginGraph(HGraph graph) {
    if (!graph.entry.hasGuards()) return;
    addIndentation();
    buffer.add('switch (state) {\n');
    indent++;
    addIndentation();
    buffer.add('case 0:\n');
    indent++;

    // The setup phase of a bailout function sets up the environment for
    // each bailout target. Each bailout target will populate this
    // setup phase. It is put at the beginning of the function.
    setup.add('  switch (state) {\n');
  }

  void endGraph(HGraph graph) {
    if (!graph.entry.hasGuards()) return;
    indent--; // Close original case.
    indent--;
    addIndentation();
    buffer.add('}\n');  // Close 'switch'.
    setup.add('  }\n');
  }

  // For instructions that reference a guard or a check, we change that
  // reference to the instruction they guard against. Therefore, we must
  // use that instruction when restoring the environment.
  HInstruction unwrap(HInstruction argument) {
    if (argument is HIntegerCheck) {
      HIntegerCheck instruction = argument;
      return unwrap(instruction.value);
    } else if (argument is HBoundsCheck) {
      HBoundsCheck instruction = argument;
      return unwrap(instruction.index);
    } else if (argument is HTypeGuard) {
      HTypeGuard instruction = argument;
      return unwrap(instruction.guarded);
    } else {
      return argument;
    }
  }

  bool handleLoop(HBasicBlock node) => false;

  void visitTypeGuard(HTypeGuard node) {
    indent--;
    addIndentation();
    buffer.add('case ${node.state}:\n');
    indent++;
    addIndentation();
    buffer.add('state = 0;\n');

    setup.add('    case ${node.state}:\n');
    int i = 0;
    for (HInstruction input in node.inputs) {
      HInstruction instruction = unwrap(input);
      setup.add('      ${temporary(instruction)} = env$i;\n');
      i++;
    }
    if (i > maxBailoutParameters) maxBailoutParameters = i;
    setup.add('      break;\n');
  }

  void startBailoutCase(List<HTypeGuard> bailouts1,
                        List<HTypeGuard> bailouts2) {
    indent--;
    handleBailoutCase(bailouts1);
    handleBailoutCase(bailouts2);
    indent++;
  }

  void handleBailoutCase(List<HTypeGuard> guards) {
    for (int i = 0, len = guards.length; i < len; i++) {
      addIndentation();
      buffer.add('case ${guards[i].state}:\n');
    }
  }

  void startBailoutSwitch() {
    addIndentation();
    buffer.add('switch (state) {\n');
    indent++;
    addIndentation();
    buffer.add('case 0:\n');
    indent++;
  }

  void endBailoutSwitch() {
    indent--; // Close 'case'.
    indent--;
    addIndentation();
    buffer.add('}\n');  // Close 'switch'.
  }


  void beginLoop(HBasicBlock block) {
    // TODO(ngeoffray): Don't put labels on loops that don't bailout.
    String newLabel = pushLabel();
    if (block.hasGuards()) {
      startBailoutCase(block.guards, const <HTypeGuard>[]);
    }

    addIndentation();
    for (SourceString label in block.loopInformation.labels) {
      writeLabel(label);
      buffer.add(":");
    }
    buffer.add('$newLabel: while (true) {\n');
    indent++;

    if (block.hasGuards()) {
      startBailoutSwitch();
    }
  }

  void endLoop(HBasicBlock block) {
    popLabel();
    HBasicBlock header = block.isLoopHeader() ? block : block.parentLoopHeader;
    if (header.hasGuards()) {
      endBailoutSwitch();
    }
    indent--;
    addIndentation();
    buffer.add('}\n');  // Close 'while'.
  }

  void handleLoopCondition(HLoopBranch node) {
    buffer.add('if (!');
    use(node.inputs[0], JSPrecedence.PREFIX_PRECEDENCE);
    buffer.add(') break ${currentLabel()};\n');
  }

  void startIf(HIf node) {
    bool hasGuards = node.thenBlock.hasGuards()
        || (node.hasElse && node.elseBlock.hasGuards());
    if (hasGuards) {
      startBailoutCase(node.thenBlock.guards,
          node.hasElse ? node.elseBlock.guards : const <HTypeGuard>[]);
    }
  }

  void endIf(HIf node) {
    indent--;
    addIndentation();
    buffer.add('}\n');
  }

  void startThen(HIf node) {
    addIndentation();
    bool hasGuards = node.thenBlock.hasGuards()
        || (node.hasElse && node.elseBlock.hasGuards());
    buffer.add('if (');
    int precedence = JSPrecedence.EXPRESSION_PRECEDENCE;
    if (hasGuards) {
      // TODO(ngeoffray): Put the condition initialization in the
      // [setup] buffer.
      List<HTypeGuard> guards = node.thenBlock.guards;
      for (int i = 0, len = guards.length; i < len; i++) {
        buffer.add('state == ${guards[i].state} || ');
      }
      buffer.add('(state == 0 && ');
      precedence = JSPrecedence.BITWISE_OR_PRECEDENCE;
    }
    use(node.inputs[0], precedence);
    if (hasGuards) {
      buffer.add(')');
    }
    buffer.add(') {\n');
    indent++;
    if (node.thenBlock.hasGuards()) {
      startBailoutSwitch();
    }
  }

  void endThen(HIf node) {
    if (node.thenBlock.hasGuards()) {
      endBailoutSwitch();
    }
  }

  void startElse(HIf node) {
    indent--;
    addIndentation();
    buffer.add('} else {\n');
    indent++;
    if (node.elseBlock.hasGuards()) {
      startBailoutSwitch();
    }
  }

  void endElse(HIf node) {
    if (node.elseBlock.hasGuards()) {
      endBailoutSwitch();
    }
  }
}
