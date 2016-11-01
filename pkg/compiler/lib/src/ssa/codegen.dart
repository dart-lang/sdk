// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common/codegen.dart' show CodegenRegistry, CodegenWorkItem;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../core_types.dart' show CoreClasses;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/backend_helpers.dart' show BackendHelpers;
import '../js_backend/js_backend.dart';
import '../js_emitter/js_emitter.dart' show NativeEmitter;
import '../native/native.dart' as native;
import '../types/types.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import '../universe/use.dart' show DynamicUse, StaticUse, TypeUse;
import '../util/util.dart';
import '../world.dart' show ClosedWorld;
import 'codegen_helpers.dart';
import 'nodes.dart';
import 'variable_allocator.dart';

class SsaCodeGeneratorTask extends CompilerTask {
  final JavaScriptBackend backend;
  final Compiler compiler;
  final SourceInformationStrategy sourceInformationFactory;

  SsaCodeGeneratorTask(JavaScriptBackend backend, this.sourceInformationFactory)
      : this.backend = backend,
        this.compiler = backend.compiler,
        super(backend.compiler.measurer);

  String get name => 'SSA code generator';
  NativeEmitter get nativeEmitter => backend.emitter.nativeEmitter;

  js.Fun buildJavaScriptFunction(
      ResolvedAst resolvedAst, List<js.Parameter> parameters, js.Block body) {
    FunctionElement element = resolvedAst.element;
    js.AsyncModifier asyncModifier = element.asyncMarker.isAsync
        ? (element.asyncMarker.isYielding
            ? const js.AsyncModifier.asyncStar()
            : const js.AsyncModifier.async())
        : (element.asyncMarker.isYielding
            ? const js.AsyncModifier.syncStar()
            : const js.AsyncModifier.sync());

    return new js.Fun(parameters, body, asyncModifier: asyncModifier)
        .withSourceInformation(sourceInformationFactory
            .createBuilderForContext(resolvedAst)
            .buildDeclaration(resolvedAst));
  }

  js.Expression generateCode(CodegenWorkItem work, HGraph graph) {
    if (work.element.isField) {
      return generateLazyInitializer(work, graph);
    } else {
      return generateMethod(work, graph);
    }
  }

  js.Expression generateLazyInitializer(CodegenWorkItem work, HGraph graph) {
    return measure(() {
      compiler.tracer.traceGraph("codegen", graph);
      SourceInformation sourceInformation = sourceInformationFactory
          .createBuilderForContext(work.resolvedAst)
          .buildDeclaration(work.resolvedAst);
      SsaCodeGenerator codegen = new SsaCodeGenerator(backend, work);
      codegen.visitGraph(graph);
      return new js.Fun(codegen.parameters, codegen.body)
          .withSourceInformation(sourceInformation);
    });
  }

  js.Expression generateMethod(CodegenWorkItem work, HGraph graph) {
    return measure(() {
      FunctionElement element = work.element;
      if (element.asyncMarker != AsyncMarker.SYNC) {
        work.registry.registerAsyncMarker(element);
      }
      SsaCodeGenerator codegen = new SsaCodeGenerator(backend, work);
      codegen.visitGraph(graph);
      compiler.tracer.traceGraph("codegen", graph);
      return buildJavaScriptFunction(
          work.resolvedAst, codegen.parameters, codegen.body);
    });
  }
}

typedef void EntityAction(Entity element);

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
  final CodegenWorkItem work;

  final Set<HInstruction> generateAtUseSite;
  final Set<HInstruction> controlFlowOperators;
  final Map<Entity, EntityAction> breakAction;
  final Map<Entity, EntityAction> continueAction;
  final List<js.Parameter> parameters;

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
  final Set<String> collectedVariableDeclarations;

  /**
   * Set of variables and parameters that have already been declared.
   */
  final Set<String> declaredLocals;

  HGraph currentGraph;

  // Records a block-information that is being handled specially.
  // Used to break bad recursion.
  HBlockInformation currentBlockInformation;
  // The subgraph is used to delimit traversal for some constructions, e.g.,
  // if branches.
  SubGraph subGraph;

  SsaCodeGenerator(this.backend, CodegenWorkItem work,
      {SourceInformation sourceInformation})
      : this.work = work,
        declaredLocals = new Set<String>(),
        collectedVariableDeclarations = new Set<String>(),
        currentContainer = new js.Block.empty(),
        parameters = <js.Parameter>[],
        expressionStack = <js.Expression>[],
        oldContainerStack = <js.Block>[],
        generateAtUseSite = new Set<HInstruction>(),
        controlFlowOperators = new Set<HInstruction>(),
        breakAction = new Map<Entity, EntityAction>(),
        continueAction = new Map<Entity, EntityAction>();

  Compiler get compiler => backend.compiler;

  NativeEmitter get nativeEmitter => backend.emitter.nativeEmitter;

  CodegenRegistry get registry => work.registry;

  BackendHelpers get helpers => backend.helpers;

  native.NativeEnqueuer get nativeEnqueuer {
    return compiler.enqueuer.codegen.nativeEnqueuer;
  }

  DiagnosticReporter get reporter => compiler.reporter;

  CoreClasses get coreClasses => compiler.coreClasses;

  bool isGenerateAtUseSite(HInstruction instruction) {
    return generateAtUseSite.contains(instruction);
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

  bool requiresUintConversion(instruction) {
    if (instruction.isUInt31(compiler)) return false;
    // If the result of a bit-operation is only used by other bit
    // operations, we do not have to convert to an unsigned integer.
    return hasNonBitOpUser(instruction, new Set<HPhi>());
  }

  /**
   * If the [instruction] is not `null` it will be used to attach the position
   * to the [statement].
   */
  void pushStatement(js.Statement statement) {
    assert(expressionStack.isEmpty);
    currentContainer.statements.add(statement);
  }

  void insertStatementAtStart(js.Statement statement) {
    currentContainer.statements.insert(0, statement);
  }

  /**
   * If the [instruction] is not `null` it will be used to attach the position
   * to the [expression].
   */
  pushExpressionAsStatement(
      js.Expression expression, SourceInformation sourceInformation) {
    pushStatement(new js.ExpressionStatement(expression)
        .withSourceInformation(sourceInformation));
  }

  /**
   * If the [instruction] is not `null` it will be used to attach the position
   * to the [expression].
   */
  push(js.Expression expression) {
    expressionStack.add(expression);
  }

  js.Expression pop() {
    return expressionStack.removeLast();
  }

  void preGenerateMethod(HGraph graph) {
    new SsaInstructionSelection(compiler).visitGraph(graph);
    new SsaTypeKnownRemover().visitGraph(graph);
    new SsaTrustedCheckRemover(compiler).visitGraph(graph);
    new SsaInstructionMerger(generateAtUseSite, compiler).visitGraph(graph);
    new SsaConditionMerger(generateAtUseSite, controlFlowOperators)
        .visitGraph(graph);
    SsaLiveIntervalBuilder intervalBuilder = new SsaLiveIntervalBuilder(
        compiler, generateAtUseSite, controlFlowOperators);
    intervalBuilder.visitGraph(graph);
    SsaVariableAllocator allocator = new SsaVariableAllocator(
        compiler,
        intervalBuilder.liveInstructions,
        intervalBuilder.liveIntervals,
        generateAtUseSite);
    allocator.visitGraph(graph);
    variableNames = allocator.names;
    shouldGroupVarDeclarations = allocator.names.numberOfVariables > 1;
  }

  void handleDelayedVariableDeclarations(SourceInformation sourceInformation) {
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
                      new js.VariableDeclarationList([initialization]))
                  .withSourceInformation(sourceInformation);
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
      var declarationList = new js.VariableDeclarationList(declarations)
          .withSourceInformation(sourceInformation);
      ;
      insertStatementAtStart(new js.ExpressionStatement(declarationList));
    }
  }

  visitGraph(HGraph graph) {
    preGenerateMethod(graph);
    currentGraph = graph;
    subGraph = new SubGraph(graph.entry, graph.exit);
    visitBasicBlock(graph.entry);
    handleDelayedVariableDeclarations(graph.sourceInformation);
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
    // isn't used can't be in a declaration.
    int result = TYPE_DECLARATION;
    HBasicBlock basicBlock = limits.start;
    do {
      HInstruction current = basicBlock.first;
      while (current != basicBlock.last) {
        // E.g, bounds check.
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
      if (result is js.Block) return unwrapStatement(result);
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
      js.Expression result = sequenceElements.removeLast();
      while (sequenceElements.isNotEmpty) {
        result = new js.Binary(',', sequenceElements.removeLast(), result);
      }
      return result;
    }
  }

  /**
    * Only visits the arguments starting at inputs[HInvoke.ARGUMENTS_OFFSET].
    */
  List<js.Expression> visitArguments(List<HInstruction> inputs,
      {int start: HInvoke.ARGUMENTS_OFFSET}) {
    assert(inputs.length >= start);
    List<js.Expression> result = new List<js.Expression>(inputs.length - start);
    for (int i = start; i < inputs.length; i++) {
      use(inputs[i]);
      result[i - start] = pop();
    }
    return result;
  }

  bool isVariableDeclared(String variableName) {
    return declaredLocals.contains(variableName) ||
        collectedVariableDeclarations.contains(variableName);
  }

  js.Expression generateExpressionAssignment(
      String variableName, js.Expression value) {
    if (value is js.Binary) {
      js.Binary binary = value;
      String op = binary.op;
      if (op == '+' ||
          op == '-' ||
          op == '/' ||
          op == '*' ||
          op == '%' ||
          op == '^' ||
          op == '&' ||
          op == '|') {
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
    return new js.Assignment(new js.VariableUse(variableName), value)
        .withSourceInformation(value.sourceInformation);
  }

  void assignVariable(String variableName, js.Expression value,
      SourceInformation sourceInformation) {
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

      pushExpressionAsStatement(
          new js.VariableDeclarationList(
              <js.VariableInitialization>[initialization]),
          sourceInformation);
    } else {
      // Otherwise we are just going to use it.  If we have not already declared
      // it then we make sure we will declare it later.
      if (!declaredLocals.contains(variableName)) {
        collectedVariableDeclarations.add(variableName);
      }
      pushExpressionAsStatement(
          generateExpressionAssignment(variableName, value), sourceInformation);
    }
  }

  void define(HInstruction instruction) {
    // For simple type checks like i = intTypeCheck(i), we don't have to
    // emit an assignment, because the intTypeCheck just returns its
    // argument.
    bool needsAssignment = true;
    if (instruction is HTypeConversion) {
      HTypeConversion typeConversion = instruction;
      String inputName = variableNames.getName(typeConversion.checkedInput);
      if (variableNames.getName(instruction) == inputName) {
        needsAssignment = false;
      }
    }
    if (instruction is HLocalValue) {
      needsAssignment = false;
    }

    if (needsAssignment &&
        !instruction.isControlFlow() &&
        variableNames.hasName(instruction)) {
      visitExpression(instruction);
      assignVariable(variableNames.getName(instruction), pop(),
          instruction.sourceInformation);
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
    } else if (argument is HCheck && !variableNames.hasName(argument)) {
      HCheck check = argument;
      // This can only happen if the checked node does not have a name.
      assert(!variableNames.hasName(check.checkedInput));
      use(check.checkedInput);
    } else {
      assert(variableNames.hasName(argument));
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
      js.Expression expression = pop();
      pushExpressionAsStatement(expression, node.sourceInformation);
    }
  }

  void continueAsBreak(LabelDefinition target) {
    pushStatement(new js.Break(backend.namer.continueLabelName(target)));
  }

  void implicitContinueAsBreak(JumpTarget target) {
    pushStatement(
        new js.Break(backend.namer.implicitContinueLabelName(target)));
  }

  void implicitBreakWithLabel(JumpTarget target) {
    pushStatement(new js.Break(backend.namer.implicitBreakLabelName(target)));
  }

  js.Statement wrapIntoLabels(
      js.Statement result, List<LabelDefinition> labels) {
    for (LabelDefinition label in labels) {
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
    HSwitch switchInstruction = info.expression.end.last;
    List<HInstruction> inputs = switchInstruction.inputs;
    List<HBasicBlock> successors = switchInstruction.block.successors;

    js.Block oldContainer = currentContainer;
    for (int inputIndex = 1, statementIndex = 0;
        inputIndex < inputs.length;
        statementIndex++) {
      HBasicBlock successor = successors[inputIndex - 1];
      // If liveness analysis has figured out that this case is dead,
      // omit the code for it.
      if (successor.isLive) {
        do {
          visit(inputs[inputIndex]);
          currentContainer = new js.Block.empty();
          cases.add(new js.Case(pop(), currentContainer));
          inputIndex++;
        } while ((successors[inputIndex - 1] == successor) &&
            (inputIndex < inputs.length));

        generateStatements(info.statements[statementIndex]);
      } else {
        // Skip all the case statements that belong to this
        // block.
        while ((successors[inputIndex - 1] == successor) &&
            (inputIndex < inputs.length)) {
          ++inputIndex;
        }
      }
    }

    // If the default case is dead, we omit it. Likewise, if it is an
    // empty block, we omit it, too.
    if (info.statements.last.start.isLive) {
      currentContainer = new js.Block.empty();
      generateStatements(info.statements.last);
      if (currentContainer.statements.isNotEmpty) {
        cases.add(new js.Default(currentContainer));
      }
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
      void register(ClassElement classElement) {
        if (classElement != null) {
          registry.registerInstantiatedClass(classElement);
        }
      }

      register(helpers.jsPlainJavaScriptObjectClass);
      register(helpers.jsUnknownJavaScriptObjectClass);

      HLocalValue exception = info.catchVariable;
      String name = variableNames.getName(exception);
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
      case HLoopBlockInformation.SWITCH_CONTINUE_LOOP:
        HBlockInformation initialization = info.initializer;
        int initializationType = TYPE_STATEMENT;
        if (initialization != null) {
          initializationType = expressionType(initialization);
          if (initializationType == TYPE_STATEMENT) {
            generateStatements(initialization);
            initialization = null;
          }
        }

        // We inserted a basic block to avoid critical edges. This block is
        // part of the LoopBlockInformation and must therefore be handled here.
        js.Block oldContainer = currentContainer;
        js.Block avoidContainer = new js.Block.empty();
        currentContainer = avoidContainer;
        assignPhisOfSuccessors(condition.end.successors.last);
        bool hasPhiUpdates = !avoidContainer.statements.isEmpty;
        currentContainer = oldContainer;

        if (isConditionExpression &&
            !hasPhiUpdates &&
            info.updates != null &&
            isJSExpression(info.updates)) {
          // If we have an updates graph, and it's expressible as an
          // expression, generate a for-loop.
          js.Expression jsInitialization = null;
          if (initialization != null) {
            int delayedVariablesCount = collectedVariableDeclarations.length;
            jsInitialization = generateExpression(initialization);
            if (!shouldGroupVarDeclarations &&
                delayedVariablesCount < collectedVariableDeclarations.length) {
              // We just added a new delayed variable-declaration. See if we can
              // put in a 'var' in front of the initialization to make it go
              // away. We walk the 'tree' of comma-operators to find the
              // expressions and see if they are all assignments that can be
              // converted into declarations.

              List<js.Assignment> assignments;

              bool allSimpleAssignments(js.Expression expression) {
                if (expression is js.Assignment) {
                  js.Assignment assignment = expression;
                  if (assignment.leftHandSide is js.VariableUse &&
                      !assignment.isCompound) {
                    if (assignments == null) assignments = <js.Assignment>[];
                    assignments.add(expression);
                    return true;
                  }
                } else if (expression.isCommaOperator) {
                  js.Binary binary = expression;
                  return allSimpleAssignments(binary.left) &&
                      allSimpleAssignments(binary.right);
                }
                return false;
              }

              if (allSimpleAssignments(jsInitialization)) {
                List<js.VariableInitialization> inits =
                    <js.VariableInitialization>[];
                for (js.Assignment assignment in assignments) {
                  String id = (assignment.leftHandSide as js.VariableUse).name;
                  js.Node declaration = new js.VariableDeclaration(id);
                  inits.add(new js.VariableInitialization(
                      declaration, assignment.value));
                  collectedVariableDeclarations.remove(id);
                  declaredLocals.add(id);
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
          oldContainer = currentContainer;
          js.Statement body = new js.Block.empty();
          currentContainer = body;
          visitBodyIgnoreLabels(info);
          currentContainer = oldContainer;
          body = unwrapStatement(body);
          loop = new js.For(jsInitialization, jsCondition, jsUpdates, body)
              .withSourceInformation(info.sourceInformation);
        } else {
          // We have either no update graph, or it's too complex to
          // put in an expression.
          if (initialization != null) {
            generateStatements(initialization);
          }
          js.Expression jsCondition;
          js.Block oldContainer = currentContainer;
          js.Statement body = new js.Block.empty();
          if (isConditionExpression && !hasPhiUpdates) {
            jsCondition = generateExpression(condition);
            currentContainer = body;
          } else {
            jsCondition = newLiteralBool(true, info.sourceInformation);
            currentContainer = body;
            generateStatements(condition);
            use(condition.conditionExpression);
            js.Expression ifTest = new js.Prefix("!", pop());
            js.Statement jsBreak = new js.Break(null);
            js.Statement exitLoop;
            if (avoidContainer.statements.isEmpty) {
              exitLoop = jsBreak;
            } else {
              avoidContainer.statements.add(jsBreak);
              exitLoop = avoidContainer;
            }
            pushStatement(new js.If.noElse(ifTest, exitLoop));
          }
          if (info.updates != null) {
            wrapLoopBodyForContinue(info);
            generateStatements(info.updates);
          } else {
            visitBodyIgnoreLabels(info);
          }
          currentContainer = oldContainer;
          body = unwrapStatement(body);
          loop = new js.While(jsCondition, body)
              .withSourceInformation(info.sourceInformation);
        }
        break;
      case HLoopBlockInformation.DO_WHILE_LOOP:
        if (info.initializer != null) {
          generateStatements(info.initializer);
        }
        // We inserted a basic block to avoid critical edges. This block is
        // part of the LoopBlockInformation and must therefore be handled here.
        js.Block oldContainer = currentContainer;
        js.Block exitAvoidContainer = new js.Block.empty();
        currentContainer = exitAvoidContainer;
        assignPhisOfSuccessors(condition.end.successors.last);
        bool hasExitPhiUpdates = !exitAvoidContainer.statements.isEmpty;
        currentContainer = oldContainer;

        oldContainer = currentContainer;
        js.Block body = new js.Block.empty();
        // If there are phi copies in the block that jumps to the
        // loop entry, we must emit the condition like this:
        // do {
        //   body;
        //   if (condition) {
        //     phi updates;
        //     continue;
        //   } else {
        //     break;
        //   }
        // } while (true);
        HBasicBlock avoidEdge = info.end.successors[0];
        js.Block updateBody = new js.Block.empty();
        currentContainer = updateBody;
        assignPhisOfSuccessors(avoidEdge);
        bool hasPhiUpdates = !updateBody.statements.isEmpty;
        currentContainer = body;
        visitBodyIgnoreLabels(info);
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
        if (jsCondition == null) {
          // If the condition is dead code, we turn the do-while into
          // a simpler while because we will never reach the condition
          // at the end of the loop anyway.
          loop = new js.While(newLiteralBool(true, info.sourceInformation),
                  unwrapStatement(body))
              .withSourceInformation(info.sourceInformation);
        } else {
          if (hasPhiUpdates || hasExitPhiUpdates) {
            updateBody.statements.add(new js.Continue(null));
            js.Statement jsBreak = new js.Break(null);
            js.Statement exitLoop;
            if (exitAvoidContainer.statements.isEmpty) {
              exitLoop = jsBreak;
            } else {
              exitAvoidContainer.statements.add(jsBreak);
              exitLoop = exitAvoidContainer;
            }
            body.statements.add(new js.If(jsCondition, updateBody, exitLoop));
            jsCondition = newLiteralBool(true, info.sourceInformation);
          }
          loop = new js.Do(unwrapStatement(body), jsCondition)
              .withSourceInformation(info.sourceInformation);
        }
        currentContainer = oldContainer;
        break;
      default:
        reporter.internalError(condition.conditionExpression,
            'Unexpected loop kind: ${info.kind}.');
    }
    js.Statement result = loop;
    if (info.kind == HLoopBlockInformation.SWITCH_CONTINUE_LOOP) {
      String continueLabelString =
          backend.namer.implicitContinueLabelName(info.target);
      result = new js.LabeledStatement(continueLabelString, result);
    }
    pushStatement(wrapIntoLabels(result, info.labels));
    return true;
  }

  bool visitLabeledBlockInfo(HLabeledBlockInformation labeledBlockInfo) {
    Link<Entity> continueOverrides = const Link<Entity>();

    js.Block oldContainer = currentContainer;
    js.Block body = new js.Block.empty();
    js.Statement result = body;

    currentContainer = body;

    // If [labeledBlockInfo.isContinue], the block is an artificial
    // block around the body of a loop with an update block, so that
    // continues of the loop can be written as breaks of the body
    // block.
    if (labeledBlockInfo.isContinue) {
      for (LabelDefinition label in labeledBlockInfo.labels) {
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
      JumpTarget target = labeledBlockInfo.target;
      String labelName = backend.namer.implicitContinueLabelName(target);
      result = new js.LabeledStatement(labelName, result);
      continueAction[target] = implicitContinueAsBreak;
      continueOverrides = continueOverrides.prepend(target);
    } else {
      for (LabelDefinition label in labeledBlockInfo.labels) {
        if (label.isBreakTarget) {
          String labelName = backend.namer.breakLabelName(label);
          result = new js.LabeledStatement(labelName, result);
        }
      }
    }
    JumpTarget target = labeledBlockInfo.target;
    if (target.isSwitch) {
      // This is an extra block around a switch that is generated
      // as a nested if/else chain. We add an extra break target
      // so that case code can break.
      String labelName = backend.namer.implicitBreakLabelName(target);
      result = new js.LabeledStatement(labelName, result);
      breakAction[target] = implicitBreakWithLabel;
    }

    currentContainer = body;
    generateStatements(labeledBlockInfo.body);

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
    JumpTarget target = info.target;
    if (target != null && target.isContinueTarget) {
      js.Block oldContainer = currentContainer;
      js.Block body = new js.Block.empty();
      currentContainer = body;
      js.Statement result = body;
      for (LabelDefinition label in info.labels) {
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
      for (LabelDefinition label in info.labels) {
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
    if (!node.isLive) return;

    // Abort traversal if we are leaving the currently active sub-graph.
    if (!subGraph.contains(node)) return;

    // If this node has block-structure based information attached,
    // try using that to traverse from here.
    if (node.blockFlow != null && handleBlockFlow(node.blockFlow)) {
      return;
    }
    iterateBasicBlock(node);
  }

  void emitAssignment(String destination, String source) {
    assignVariable(destination, new js.VariableUse(source), null);
  }

  /**
   * Sequentialize a list of conceptually parallel copies. Parallel
   * copies may contain cycles, that this method breaks.
   */
  void sequentializeCopies(Iterable<Copy> copies, String tempName,
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
      if (currentLocation[current] != null &&
          current != currentLocation[initialValue[current]]) {
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
    Iterable<Copy> copies = handler.copies.map((Copy copy) {
      return new Copy(variableNames.getName(copy.source),
          variableNames.getName(copy.destination));
    });

    sequentializeCopies(copies, variableNames.getSwapTemp(), emitAssignment);

    for (Copy copy in handler.assignments) {
      String name = variableNames.getName(copy.destination);
      use(copy.source);
      assignVariable(name, pop(), null);
    }
  }

  void iterateBasicBlock(HBasicBlock node) {
    HInstruction instruction = node.first;
    while (!identical(instruction, node.last)) {
      if (!isGenerateAtUseSite(instruction)) {
        define(instruction);
      }
      instruction = instruction.next;
    }
    assignPhisOfSuccessors(node);
    visit(instruction);
  }

  void handleInvokeBinary(
      HInvokeBinary node, String op, SourceInformation sourceInformation) {
    use(node.left);
    js.Expression jsLeft = pop();
    use(node.right);
    push(new js.Binary(op, jsLeft, pop())
        .withSourceInformation(sourceInformation));
  }

  visitInvokeBinary(HInvokeBinary node, String op) {
    handleInvokeBinary(node, op, node.sourceInformation);
  }

  visitRelational(HRelational node, String op) {
    handleInvokeBinary(node, op, node.sourceInformation);
  }

  // We want the outcome of bit-operations to be positive. We use the unsigned
  // shift operator to achieve this.
  visitBitInvokeBinary(HBinaryBitOp node, String op) {
    visitInvokeBinary(node, op);
    if (op != '>>>' && requiresUintConversion(node)) {
      push(new js.Binary(">>>", pop(), new js.LiteralNumber("0"))
          .withSourceInformation(node.sourceInformation));
    }
  }

  visitInvokeUnary(HInvokeUnary node, String op) {
    use(node.operand);
    push(
        new js.Prefix(op, pop()).withSourceInformation(node.sourceInformation));
  }

  // We want the outcome of bit-operations to be positive. We use the unsigned
  // shift operator to achieve this.
  visitBitInvokeUnary(HInvokeUnary node, String op) {
    visitInvokeUnary(node, op);
    if (requiresUintConversion(node)) {
      push(new js.Binary(">>>", pop(), new js.LiteralNumber("0"))
          .withSourceInformation(node.sourceInformation));
    }
  }

  void emitIdentityComparison(
      HIdentity instruction, SourceInformation sourceInformation,
      {bool inverse: false}) {
    String op = instruction.singleComparisonOp;
    HInstruction left = instruction.left;
    HInstruction right = instruction.right;
    if (op != null) {
      use(left);
      js.Expression jsLeft = pop();
      use(right);
      push(new js.Binary(mapRelationalOperator(op, inverse), jsLeft, pop())
          .withSourceInformation(sourceInformation));
    } else {
      assert(NullConstantValue.JsNull == 'null');
      use(left);
      js.Binary leftEqualsNull =
          new js.Binary("==", pop(), new js.LiteralNull());
      use(right);
      js.Binary rightEqualsNull = new js.Binary(
          mapRelationalOperator("==", inverse), pop(), new js.LiteralNull());
      use(right);
      use(left);
      js.Binary tripleEq =
          new js.Binary(mapRelationalOperator("===", inverse), pop(), pop());

      push(new js.Conditional(leftEqualsNull, rightEqualsNull, tripleEq)
          .withSourceInformation(sourceInformation));
    }
  }

  visitIdentity(HIdentity node) {
    emitIdentityComparison(node, node.sourceInformation, inverse: false);
  }

  visitAdd(HAdd node) => visitInvokeBinary(node, '+');
  visitDivide(HDivide node) => visitInvokeBinary(node, '/');
  visitMultiply(HMultiply node) => visitInvokeBinary(node, '*');
  visitSubtract(HSubtract node) => visitInvokeBinary(node, '-');
  visitBitAnd(HBitAnd node) => visitBitInvokeBinary(node, '&');
  visitBitNot(HBitNot node) => visitBitInvokeUnary(node, '~');
  visitBitOr(HBitOr node) => visitBitInvokeBinary(node, '|');
  visitBitXor(HBitXor node) => visitBitInvokeBinary(node, '^');
  visitShiftLeft(HShiftLeft node) => visitBitInvokeBinary(node, '<<');
  visitShiftRight(HShiftRight node) => visitBitInvokeBinary(node, '>>>');

  visitTruncatingDivide(HTruncatingDivide node) {
    assert(node.isUInt31(compiler));
    // TODO(karlklose): Enable this assertion again when type propagation is
    // fixed. Issue 23555.
//    assert(node.left.isUInt32(compiler));
    assert(node.right.isPositiveInteger(compiler));
    use(node.left);
    js.Expression jsLeft = pop();
    use(node.right);
    push(new js.Binary('/', jsLeft, pop())
        .withSourceInformation(node.sourceInformation));
    push(new js.Binary('|', pop(), new js.LiteralNumber("0"))
        .withSourceInformation(node.sourceInformation));
  }

  visitNegate(HNegate node) => visitInvokeUnary(node, '-');

  visitLess(HLess node) => visitRelational(node, '<');
  visitLessEqual(HLessEqual node) => visitRelational(node, '<=');
  visitGreater(HGreater node) => visitRelational(node, '>');
  visitGreaterEqual(HGreaterEqual node) => visitRelational(node, '>=');

  visitBoolify(HBoolify node) {
    assert(node.inputs.length == 1);
    use(node.inputs[0]);
    push(new js.Binary(
            '===', pop(), newLiteralBool(true, node.sourceInformation))
        .withSourceInformation(node.sourceInformation));
  }

  visitExit(HExit node) {
    // Don't do anything.
  }

  visitGoto(HGoto node) {
    HBasicBlock block = node.block;
    assert(block.successors.length == 1);
    List<HBasicBlock> dominated = block.dominatedBlocks;
    // With the exception of the entry-node which dominates its successor
    // and the exit node, no block finishing with a 'goto' can have more than
    // one dominated block (since it has only one successor).
    // If the successor is dominated by another block, then the other block
    // is responsible for visiting the successor.
    if (dominated.isEmpty) return;
    if (dominated.length > 2) {
      reporter.internalError(node, 'dominated.length = ${dominated.length}');
    }
    if (dominated.length == 2 && block != currentGraph.entry) {
      reporter.internalError(node, 'node.block != currentGraph.entry');
    }
    assert(dominated[0] == block.successors[0]);
    visitBasicBlock(dominated[0]);
  }

  visitLoopBranch(HLoopBranch node) {
    assert(node.block == subGraph.end);
    // We are generating code for a loop condition.
    // If we are generating the subgraph as an expression, the
    // condition will be generated as the expression.
    // Otherwise, we don't generate the expression, and leave that
    // to the code that called [visitSubGraph].
    if (isGeneratingExpression) {
      use(node.inputs[0]);
    }
  }

  /**
   * Checks if [map] contains an [EntityAction] for [entity], and
   * if so calls that action and returns true.
   * Otherwise returns false.
   */
  bool tryCallAction(Map<Entity, EntityAction> map, Entity entity) {
    EntityAction action = map[entity];
    if (action == null) return false;
    action(entity);
    return true;
  }

  visitBreak(HBreak node) {
    assert(node.block.successors.length == 1);
    if (node.label != null) {
      LabelDefinition label = node.label;
      if (!tryCallAction(breakAction, label)) {
        pushStatement(new js.Break(backend.namer.breakLabelName(label))
            .withSourceInformation(node.sourceInformation));
      }
    } else {
      JumpTarget target = node.target;
      if (!tryCallAction(breakAction, target)) {
        if (node.breakSwitchContinueLoop) {
          pushStatement(
              new js.Break(backend.namer.implicitContinueLabelName(target))
                  .withSourceInformation(node.sourceInformation));
        } else {
          pushStatement(
              new js.Break(null).withSourceInformation(node.sourceInformation));
        }
      }
    }
  }

  visitContinue(HContinue node) {
    assert(node.block.successors.length == 1);
    if (node.label != null) {
      LabelDefinition label = node.label;
      if (!tryCallAction(continueAction, label)) {
        // TODO(floitsch): should this really be the breakLabelName?
        pushStatement(new js.Continue(backend.namer.breakLabelName(label))
            .withSourceInformation(node.sourceInformation));
      }
    } else {
      JumpTarget target = node.target;
      if (!tryCallAction(continueAction, target)) {
        if (target.isSwitch) {
          pushStatement(
              new js.Continue(backend.namer.implicitContinueLabelName(target))
                  .withSourceInformation(node.sourceInformation));
        } else {
          pushStatement(new js.Continue(null)
              .withSourceInformation(node.sourceInformation));
        }
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
    // information in [visitTryInfo].
    reporter.internalError(node, 'visitTry should not be called.');
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
    if (!atUseSite &&
        variableNames.getName(phi) == variableNames.getName(phi.inputs[1])) {
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

    js.Statement code;
    // Peephole rewrites:
    //
    //     if (e); else S;   -->   if(!e) S;
    //
    //     if (e);   -->   e;
    //
    // TODO(sra): This peephole optimization would be better done as an SSA
    // optimization.
    if (thenPart is js.EmptyStatement) {
      if (elsePart is js.EmptyStatement) {
        code = new js.ExpressionStatement(test);
      } else {
        code = new js.If.noElse(new js.Prefix('!', test), elsePart);
      }
    } else {
      code = new js.If(test, thenPart, elsePart);
    }
    pushStatement(code.withSourceInformation(node.sourceInformation));
  }

  visitIf(HIf node) {
    if (tryControlFlowOperation(node)) return;

    HInstruction condition = node.inputs[0];
    HIfBlockInformation info = node.blockInformation.body;

    if (condition.isConstant()) {
      HConstant constant = condition;
      if (constant.constant.isTrue) {
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

  void visitInterceptor(HInterceptor node) {
    if (node.isConditionalConstantInterceptor) {
      assert(node.inputs.length == 2);
      use(node.receiver);
      js.Expression receiverExpression = pop();
      use(node.conditionalConstantInterceptor);
      js.Expression constant = pop();
      push(js.js('# && #', [receiverExpression, constant]));
    } else {
      assert(node.inputs.length == 1);
      registry.registerSpecializedGetInterceptor(node.interceptedClasses);
      js.Name name =
          backend.namer.nameForGetInterceptor(node.interceptedClasses);
      var isolate = new js.VariableUse(
          backend.namer.globalObjectFor(helpers.interceptorsLibrary));
      use(node.receiver);
      List<js.Expression> arguments = <js.Expression>[pop()];
      push(js
          .propertyCall(isolate, name, arguments)
          .withSourceInformation(node.sourceInformation));
      registry.registerUseInterceptor();
    }
  }

  visitInvokeDynamicMethod(HInvokeDynamicMethod node) {
    use(node.receiver);
    js.Expression object = pop();
    String methodName;
    List<js.Expression> arguments = visitArguments(node.inputs);
    Element target = node.element;

    // TODO(herhut): The namer should return the appropriate backendname here.
    if (target != null && !node.isInterceptedCall) {
      if (target == helpers.jsArrayAdd) {
        methodName = 'push';
      } else if (target == helpers.jsArrayRemoveLast) {
        methodName = 'pop';
      } else if (target == helpers.jsStringSplit) {
        methodName = 'split';
        // Split returns a List, so we make sure the backend knows the
        // list class is instantiated.
        registry.registerInstantiatedClass(coreClasses.listClass);
      } else if (backend.isNative(target) &&
          target.isFunction &&
          !node.isInterceptedCall) {
        // A direct (i.e. non-interceptor) native call is the result of
        // optimization.  The optimization ensures any type checks or
        // conversions have been satisified.
        methodName = backend.nativeData.getFixedBackendName(target);
      }
    }

    js.Name methodLiteral;
    if (methodName == null) {
      methodLiteral = backend.namer.invocationName(node.selector);
      registerMethodInvoke(node);
    } else {
      methodLiteral = backend.namer.asName(methodName);
    }
    push(js
        .propertyCall(object, methodLiteral, arguments)
        .withSourceInformation(node.sourceInformation));
  }

  void visitInvokeConstructorBody(HInvokeConstructorBody node) {
    use(node.inputs[0]);
    js.Expression object = pop();
    js.Name methodName = backend.namer.instanceMethodName(node.element);
    List<js.Expression> arguments = visitArguments(node.inputs);
    push(js
        .propertyCall(object, methodName, arguments)
        .withSourceInformation(node.sourceInformation));
    registry.registerStaticUse(new StaticUse.constructorBodyInvoke(
        node.element, new CallStructure.unnamed(arguments.length)));
  }

  void visitOneShotInterceptor(HOneShotInterceptor node) {
    List<js.Expression> arguments = visitArguments(node.inputs);
    var isolate = new js.VariableUse(
        backend.namer.globalObjectFor(helpers.interceptorsLibrary));
    Selector selector = node.selector;
    js.Name methodName = backend.registerOneShotInterceptor(selector);
    push(js
        .propertyCall(isolate, methodName, arguments)
        .withSourceInformation(node.sourceInformation));
    if (selector.isGetter) {
      registerGetter(node);
    } else if (selector.isSetter) {
      registerSetter(node);
    } else {
      registerMethodInvoke(node);
    }
    registry.registerUseInterceptor();
  }

  TypeMask getOptimizedSelectorFor(
      HInvokeDynamic node, Selector selector, TypeMask mask) {
    if (node.element != null) {
      // Create an artificial type mask to make sure only
      // [node.element] will be enqueued. We're not using the receiver
      // type because our optimizations might end up in a state where the
      // invoke dynamic knows more than the receiver.
      ClassElement enclosing = node.element.enclosingClass;
      if (compiler.closedWorld.isInstantiated(enclosing)) {
        return new TypeMask.nonNullExact(
            enclosing.declaration, compiler.closedWorld);
      } else {
        // The element is mixed in so a non-null subtype mask is the most
        // precise we have.
        assert(invariant(node, compiler.closedWorld.isUsedAsMixin(enclosing),
            message: "Element ${node.element} from $enclosing expected "
                "to be mixed in."));
        return new TypeMask.nonNullSubtype(
            enclosing.declaration, compiler.closedWorld);
      }
    }
    // If [JSInvocationMirror._invokeOn] is enabled, and this call
    // might hit a `noSuchMethod`, we register an untyped selector.
    return compiler.closedWorld.extendMaskIfReachesAll(selector, mask);
  }

  void registerMethodInvoke(HInvokeDynamic node) {
    Selector selector = node.selector;

    // If we don't know what we're calling or if we are calling a getter,
    // we need to register that fact that we may be calling a closure
    // with the same arguments.
    Element target = node.element;
    if (target == null || target.isGetter) {
      // TODO(kasperl): If we have a typed selector for the call, we
      // may know something about the types of closures that need
      // the specific closure call method.
      Selector call = new Selector.callClosureFrom(selector);
      registry.registerDynamicUse(new DynamicUse(call, null));
    }
    if (target != null) {
      // This is a dynamic invocation which we have found to have a single
      // target but for some reason haven't inlined. We are _still_ accessing
      // the target dynamically but we don't need to enqueue more than target
      // for this to work.
      assert(invariant(node, selector.applies(target),
          message: '$selector does not apply to $target'));
      registry.registerStaticUse(
          new StaticUse.directInvoke(target, selector.callStructure));
    } else {
      TypeMask mask = getOptimizedSelectorFor(node, selector, node.mask);
      registry.registerDynamicUse(new DynamicUse(selector, mask));
    }
  }

  void registerSetter(HInvokeDynamic node) {
    if (node.element != null) {
      // This is a dynamic update which we have found to have a single
      // target but for some reason haven't inlined. We are _still_ accessing
      // the target dynamically but we don't need to enqueue more than target
      // for this to work.
      registry.registerStaticUse(new StaticUse.directSet(node.element));
    } else {
      Selector selector = node.selector;
      TypeMask mask = getOptimizedSelectorFor(node, selector, node.mask);
      registry.registerDynamicUse(new DynamicUse(selector, mask));
    }
  }

  void registerGetter(HInvokeDynamic node) {
    if (node.element != null &&
        (node.element.isGetter || node.element.isField)) {
      // This is a dynamic read which we have found to have a single target but
      // for some reason haven't inlined. We are _still_ accessing the target
      // dynamically but we don't need to enqueue more than target for this to
      // work. The test above excludes non-getter functions since the element
      // represents two targets - a tearoff getter and the torn-off method.
      registry.registerStaticUse(new StaticUse.directGet(node.element));
    } else {
      Selector selector = node.selector;
      TypeMask mask = getOptimizedSelectorFor(node, selector, node.mask);
      registry.registerDynamicUse(new DynamicUse(selector, mask));
    }
  }

  visitInvokeDynamicSetter(HInvokeDynamicSetter node) {
    use(node.receiver);
    js.Name name = backend.namer.invocationName(node.selector);
    push(js
        .propertyCall(pop(), name, visitArguments(node.inputs))
        .withSourceInformation(node.sourceInformation));
    registerSetter(node);
  }

  visitInvokeDynamicGetter(HInvokeDynamicGetter node) {
    use(node.receiver);
    js.Name name = backend.namer.invocationName(node.selector);
    push(js
        .propertyCall(pop(), name, visitArguments(node.inputs))
        .withSourceInformation(node.sourceInformation));
    registerGetter(node);
  }

  visitInvokeClosure(HInvokeClosure node) {
    Selector call = new Selector.callClosureFrom(node.selector);
    use(node.receiver);
    push(js
        .propertyCall(pop(), backend.namer.invocationName(call),
            visitArguments(node.inputs))
        .withSourceInformation(node.sourceInformation));
    registry.registerDynamicUse(new DynamicUse(call, null));
  }

  visitInvokeStatic(HInvokeStatic node) {
    Element element = node.element;
    List<DartType> instantiatedTypes = node.instantiatedTypes;

    if (instantiatedTypes != null && !instantiatedTypes.isEmpty) {
      instantiatedTypes.forEach((type) {
        registry.registerInstantiation(type);
      });
    }

    List<js.Expression> arguments = visitArguments(node.inputs, start: 0);

    if (element == backend.helpers.checkConcurrentModificationError) {
      // Manually inline the [checkConcurrentModificationError] function.  This
      // function is only called from a for-loop update.  Ideally we would just
      // generate the conditionalcontrol flow in the builder but it adds basic
      // blocks in the loop update that interfere with other optimizations and
      // confuses loop recognition.

      assert(arguments.length == 2);
      Element throwFunction = backend.helpers.throwConcurrentModificationError;
      registry.registerStaticUse(
          new StaticUse.staticInvoke(throwFunction, CallStructure.ONE_ARG));

      // Calling using `(0, #)(#)` instead of `#(#)` separates the property load
      // of the static function access from the call.  For some reason this
      // helps V8 see that the call never happens so V8 makes the call a
      // deoptimization. This removes the call from the optimized loop, making
      // more optimizations available to the loop.  This form is 50% faster on
      // some small loop, almost as fast as loops with no concurrent
      // modification check.
      push(js.js('# || (0, #)(#)', [
        arguments[0],
        backend.emitter.staticFunctionAccess(throwFunction),
        arguments[1]
      ]));
    } else {
      CallStructure callStructure = new CallStructure.unnamed(arguments.length);
      registry.registerStaticUse(element.isConstructor
          ? new StaticUse.constructorInvoke(element, callStructure)
          : new StaticUse.staticInvoke(element, callStructure));
      push(backend.emitter.staticFunctionAccess(element));
      push(new js.Call(pop(), arguments,
          sourceInformation: node.sourceInformation));
    }
  }

  visitInvokeSuper(HInvokeSuper node) {
    Element superElement = node.element;
    ClassElement superClass = superElement.enclosingClass;
    if (superElement.isField) {
      js.Name fieldName = backend.namer.instanceFieldPropertyName(superElement);
      use(node.inputs[0]);
      js.PropertyAccess access = new js.PropertyAccess(pop(), fieldName)
          .withSourceInformation(node.sourceInformation);
      if (node.isSetter) {
        registry.registerStaticUse(superElement.isSetter
            ? new StaticUse.superSetterSet(superElement)
            : new StaticUse.superFieldSet(superElement));
        use(node.value);
        push(new js.Assignment(access, pop())
            .withSourceInformation(node.sourceInformation));
      } else {
        registry.registerStaticUse(new StaticUse.superGet(superElement));
        push(access);
      }
    } else {
      Selector selector = node.selector;
      if (!backend.maybeRegisterAliasedSuperMember(superElement, selector)) {
        js.Name methodName;
        if (selector.isGetter && !superElement.isGetter) {
          // If this is a tear-off, register the fact that a tear-off closure
          // will be created, and that this tear-off must bypass ordinary
          // dispatch to ensure the super method is invoked.
          FunctionElement helper = backend.helpers.closureFromTearOff;
          registry.registerStaticUse(new StaticUse.staticInvoke(
              helper, new CallStructure.unnamed(helper.parameters.length)));
          registry.registerStaticUse(new StaticUse.superTearOff(node.element));
          methodName = backend.namer.invocationName(selector);
        } else {
          methodName = backend.namer.instanceMethodName(superElement);
        }
        registry.registerStaticUse(new StaticUse.superInvoke(
            superElement, new CallStructure.unnamed(node.inputs.length)));
        push(js.js('#.#.call(#)', [
          backend.emitter
              .prototypeAccess(superClass, hasBeenInstantiated: true),
          methodName,
          visitArguments(node.inputs, start: 0)
        ]).withSourceInformation(node.sourceInformation));
      } else {
        use(node.receiver);
        registry.registerStaticUse(new StaticUse.superInvoke(
            superElement, new CallStructure.unnamed(node.inputs.length - 1)));
        push(js.js('#.#(#)', [
          pop(),
          backend.namer.aliasedSuperMemberPropertyName(superElement),
          visitArguments(node.inputs, start: 1)
        ]) // Skip receiver argument.
            .withSourceInformation(node.sourceInformation));
      }
    }
  }

  visitFieldGet(HFieldGet node) {
    use(node.receiver);
    Element element = node.element;
    if (node.isNullCheck) {
      // We access a JavaScript member we know all objects besides
      // null and undefined have: V8 does not like accessing a member
      // that does not exist.
      push(new js.PropertyAccess.field(pop(), 'toString')
          .withSourceInformation(node.sourceInformation));
    } else if (element == helpers.jsIndexableLength) {
      // We're accessing a native JavaScript property called 'length'
      // on a JS String or a JS array. Therefore, the name of that
      // property should not be mangled.
      push(new js.PropertyAccess.field(pop(), 'length')
          .withSourceInformation(node.sourceInformation));
    } else {
      js.Name name = backend.namer.instanceFieldPropertyName(element);
      push(new js.PropertyAccess(pop(), name)
          .withSourceInformation(node.sourceInformation));
      registry.registerStaticUse(new StaticUse.fieldGet(element));
    }
  }

  visitFieldSet(HFieldSet node) {
    Element element = node.element;
    registry.registerStaticUse(new StaticUse.fieldSet(element));
    js.Name name = backend.namer.instanceFieldPropertyName(element);
    use(node.receiver);
    js.Expression receiver = pop();
    use(node.value);
    push(new js.Assignment(new js.PropertyAccess(receiver, name), pop())
        .withSourceInformation(node.sourceInformation));
  }

  visitReadModifyWrite(HReadModifyWrite node) {
    Element element = node.element;
    registry.registerStaticUse(new StaticUse.fieldGet(element));
    registry.registerStaticUse(new StaticUse.fieldSet(element));
    js.Name name = backend.namer.instanceFieldPropertyName(element);
    use(node.receiver);
    js.Expression fieldReference = new js.PropertyAccess(pop(), name);
    if (node.isPreOp) {
      push(new js.Prefix(node.jsOp, fieldReference)
          .withSourceInformation(node.sourceInformation));
    } else if (node.isPostOp) {
      push(new js.Postfix(node.jsOp, fieldReference)
          .withSourceInformation(node.sourceInformation));
    } else {
      use(node.value);
      push(new js.Assignment.compound(fieldReference, node.jsOp, pop())
          .withSourceInformation(node.sourceInformation));
    }
  }

  visitLocalGet(HLocalGet node) {
    use(node.receiver);
  }

  visitLocalSet(HLocalSet node) {
    use(node.value);
    assignVariable(
        variableNames.getName(node.receiver), pop(), node.sourceInformation);
  }

  void registerForeignTypes(HForeign node) {
    native.NativeBehavior nativeBehavior = node.nativeBehavior;
    if (nativeBehavior == null) return;
    nativeEnqueuer.registerNativeBehavior(nativeBehavior, node);
  }

  visitForeignCode(HForeignCode node) {
    List<HInstruction> inputs = node.inputs;
    if (node.isJsStatement()) {
      List<js.Expression> interpolatedExpressions = <js.Expression>[];
      for (int i = 0; i < inputs.length; i++) {
        use(inputs[i]);
        interpolatedExpressions.add(pop());
      }
      pushStatement(node.codeTemplate
          .instantiate(interpolatedExpressions)
          .withSourceInformation(node.sourceInformation));
    } else {
      List<js.Expression> interpolatedExpressions = <js.Expression>[];
      for (int i = 0; i < inputs.length; i++) {
        use(inputs[i]);
        interpolatedExpressions.add(pop());
      }
      push(node.codeTemplate
          .instantiate(interpolatedExpressions)
          .withSourceInformation(node.sourceInformation));
    }

    // TODO(sra): Tell world.nativeEnqueuer about the types created here.
    registerForeignTypes(node);
  }

  visitCreate(HCreate node) {
    js.Expression jsClassReference =
        backend.emitter.constructorAccess(node.element);
    List<js.Expression> arguments = visitArguments(node.inputs, start: 0);
    push(new js.New(jsClassReference, arguments)
        .withSourceInformation(node.sourceInformation));
    // We also use HCreate to instantiate closure classes that belong to
    // function expressions. We have to register their use here, as otherwise
    // code for them might not be emitted.
    if (node.element.isClosure) {
      registry.registerInstantiatedClass(node.element);
    }
    node.instantiatedTypes?.forEach(registry.registerInstantiation);
  }

  js.Expression newLiteralBool(
      bool value, SourceInformation sourceInformation) {
    if (compiler.options.enableMinification) {
      // Use !0 for true, !1 for false.
      return new js.Prefix("!", new js.LiteralNumber(value ? "0" : "1"))
          .withSourceInformation(sourceInformation);
    } else {
      return new js.LiteralBool(value).withSourceInformation(sourceInformation);
    }
  }

  void generateConstant(
      ConstantValue constant, SourceInformation sourceInformation) {
    if (constant.isFunction) {
      FunctionConstantValue function = constant;
      registry.registerStaticUse(new StaticUse.staticTearOff(function.element));
    }
    if (constant.isType) {
      // If the type is a web component, we need to ensure the constructors are
      // available to 'upgrade' the native object.
      TypeConstantValue type = constant;
      Element element = type.representedType.element;
      if (element != null && element.isClass) {
        registry.registerTypeConstant(element);
      }
    }
    js.Expression expression = backend.emitter.constantReference(constant);
    if (!constant.isDummy) {
      // TODO(johnniwinther): Support source information on synthetic constants.
      expression = expression.withSourceInformation(sourceInformation);
    }
    push(expression);
  }

  visitConstant(HConstant node) {
    assert(isGenerateAtUseSite(node));
    generateConstant(node.constant, node.sourceInformation);

    registry.registerCompileTimeConstant(node.constant);
  }

  visitNot(HNot node) {
    assert(node.inputs.length == 1);
    generateNot(node.inputs[0], node.sourceInformation);
  }

  static String mapRelationalOperator(String op, bool inverse) {
    Map<String, String> inverseOperator = const <String, String>{
      "==": "!=",
      "!=": "==",
      "===": "!==",
      "!==": "===",
      "<": ">=",
      "<=": ">",
      ">": "<=",
      ">=": "<"
    };
    return inverse ? inverseOperator[op] : op;
  }

  void generateNot(HInstruction input, SourceInformation sourceInformation) {
    bool canGenerateOptimizedComparison(HInstruction instruction) {
      if (instruction is! HRelational) return false;

      HRelational relational = instruction;

      HInstruction left = relational.left;
      HInstruction right = relational.right;
      if (left.isStringOrNull(compiler) && right.isStringOrNull(compiler)) {
        return true;
      }

      // This optimization doesn't work for NaN, so we only do it if the
      // type is known to be an integer.
      return left.isInteger(compiler) && right.isInteger(compiler);
    }

    bool handledBySpecialCase = false;
    if (isGenerateAtUseSite(input)) {
      handledBySpecialCase = true;
      if (input is HIs) {
        emitIs(input, '!==', sourceInformation);
      } else if (input is HIsViaInterceptor) {
        emitIsViaInterceptor(input, sourceInformation, negative: true);
      } else if (input is HNot) {
        use(input.inputs[0]);
      } else if (input is HIdentity) {
        emitIdentityComparison(input, sourceInformation, inverse: true);
      } else if (input is HBoolify) {
        use(input.inputs[0]);
        push(new js.Binary(
                "!==", pop(), newLiteralBool(true, input.sourceInformation))
            .withSourceInformation(sourceInformation));
      } else if (canGenerateOptimizedComparison(input)) {
        HRelational relational = input;
        BinaryOperation operation =
            relational.operation(backend.constantSystem);
        String op = mapRelationalOperator(operation.name, true);
        handleInvokeBinary(input, op, sourceInformation);
      } else {
        handledBySpecialCase = false;
      }
    }
    if (!handledBySpecialCase) {
      use(input);
      push(new js.Prefix("!", pop()).withSourceInformation(sourceInformation));
    }
  }

  visitParameterValue(HParameterValue node) {
    assert(!isGenerateAtUseSite(node));
    String name = variableNames.getName(node);
    parameters.add(new js.Parameter(name));
    declaredLocals.add(name);
  }

  visitLocalValue(HLocalValue node) {
    assert(!isGenerateAtUseSite(node));
    String name = variableNames.getName(node);
    collectedVariableDeclarations.add(name);
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
        generateNot(input, input.sourceInformation);
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
      pushStatement(
          new js.Return().withSourceInformation(node.sourceInformation));
    } else {
      use(node.inputs[0]);
      pushStatement(
          new js.Return(pop()).withSourceInformation(node.sourceInformation));
    }
  }

  visitThis(HThis node) {
    push(new js.This());
  }

  visitThrow(HThrow node) {
    if (node.isRethrow) {
      use(node.inputs[0]);
      pushStatement(
          new js.Throw(pop()).withSourceInformation(node.sourceInformation));
    } else {
      generateThrowWithHelper(helpers.wrapExceptionHelper, node.inputs[0],
          sourceInformation: node.sourceInformation);
    }
  }

  visitAwait(HAwait node) {
    use(node.inputs[0]);
    push(new js.Await(pop()).withSourceInformation(node.sourceInformation));
  }

  visitYield(HYield node) {
    use(node.inputs[0]);
    pushStatement(new js.DartYield(pop(), node.hasStar)
        .withSourceInformation(node.sourceInformation));
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
        if (node.index.isInteger(compiler)) {
          under = js.js("# < 0", pop());
        } else {
          js.Expression jsIndex = pop();
          under = js.js("# >>> 0 !== #", [jsIndex, jsIndex]);
        }
      } else if (!node.index.isInteger(compiler)) {
        checkInt(node.index, '!==');
        under = pop();
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
          : over == null ? under : new js.Binary("||", under, over);
      js.Statement thenBody = new js.Block.empty();
      js.Block oldContainer = currentContainer;
      currentContainer = thenBody;
      generateThrowWithHelper(helpers.throwIndexOutOfRangeException,
          [node.array, node.reportedIndex]);
      currentContainer = oldContainer;
      thenBody = unwrapStatement(thenBody);
      pushStatement(new js.If.noElse(underOver, thenBody)
          .withSourceInformation(node.sourceInformation));
    } else {
      generateThrowWithHelper(
          helpers.throwIndexOutOfRangeException, [node.array, node.index]);
    }
  }

  void generateThrowWithHelper(Element helper, argument,
      {SourceInformation sourceInformation}) {
    js.Expression jsHelper = backend.emitter.staticFunctionAccess(helper);
    List arguments = [];
    if (argument is List) {
      argument.forEach((instruction) {
        use(instruction);
        arguments.add(pop());
      });
    } else {
      use(argument);
      arguments.add(pop());
    }
    registry.registerStaticUse(new StaticUse.staticInvoke(
        helper, new CallStructure.unnamed(arguments.length)));
    js.Call value = new js.Call(jsHelper, arguments.toList(growable: false),
        sourceInformation: sourceInformation);
    // BUG(4906): Using throw/return here adds to the size of the generated code
    // but it has the advantage of explicitly telling the JS engine that
    // this code path will terminate abruptly. Needs more work.
    if (helper == helpers.wrapExceptionHelper) {
      pushStatement(
          new js.Throw(value).withSourceInformation(sourceInformation));
    } else {
      Element element = work.element;
      if (element is FunctionElement && element.asyncMarker.isYielding) {
        // `return <expr>;` is illegal in a sync* or async* function.
        // To have the async-translator working, we avoid introducing
        // `return` nodes.
        pushStatement(new js.ExpressionStatement(value)
            .withSourceInformation(sourceInformation));
      } else {
        pushStatement(
            new js.Return(value).withSourceInformation(sourceInformation));
      }
    }
  }

  visitThrowExpression(HThrowExpression node) {
    HInstruction argument = node.inputs[0];
    use(argument);

    Element helper = helpers.throwExpressionHelper;
    registry.registerStaticUse(
        new StaticUse.staticInvoke(helper, CallStructure.ONE_ARG));

    js.Expression jsHelper = backend.emitter.staticFunctionAccess(helper);
    js.Call value = new js.Call(jsHelper, [pop()])
        .withSourceInformation(node.sourceInformation);
    push(value);
  }

  void visitSwitch(HSwitch node) {
    // Switches are handled using [visitSwitchInfo].
  }

  void visitStatic(HStatic node) {
    Element element = node.element;
    assert(element.isFunction || element.isField);
    if (element.isFunction) {
      push(backend.emitter
          .isolateStaticClosureAccess(element)
          .withSourceInformation(node.sourceInformation));
      registry.registerStaticUse(new StaticUse.staticTearOff(element));
    } else {
      push(backend.emitter
          .staticFieldAccess(element)
          .withSourceInformation(node.sourceInformation));
      registry.registerStaticUse(new StaticUse.staticGet(element));
    }
  }

  void visitLazyStatic(HLazyStatic node) {
    Element element = node.element;
    registry.registerStaticUse(new StaticUse.staticInit(element));
    js.Expression lazyGetter =
        backend.emitter.isolateLazyInitializerAccess(element);
    js.Call call = new js.Call(lazyGetter, <js.Expression>[],
        sourceInformation: node.sourceInformation);
    push(call);
  }

  void visitStaticStore(HStaticStore node) {
    registry.registerStaticUse(new StaticUse.staticSet(node.element));
    js.Node variable = backend.emitter.staticFieldAccess(node.element);
    use(node.inputs[0]);
    push(new js.Assignment(variable, pop())
        .withSourceInformation(node.sourceInformation));
  }

  void visitStringConcat(HStringConcat node) {
    use(node.left);
    js.Expression jsLeft = pop();
    use(node.right);
    push(new js.Binary('+', jsLeft, pop())
        .withSourceInformation(node.sourceInformation));
  }

  void visitStringify(HStringify node) {
    HInstruction input = node.inputs.first;
    if (input.isString(compiler)) {
      use(input);
    } else if (input.isInteger(compiler) || input.isBoolean(compiler)) {
      // JavaScript's + operator with a string for the left operand will convert
      // the right operand to a string, and the conversion result is correct.
      use(input);
      if (node.usedBy.length == 1 &&
          node.usedBy[0] is HStringConcat &&
          node.usedBy[0].inputs[1] == node) {
        // The context is already <string> + value.
      } else {
        // Force an empty string for the first operand.
        push(new js.Binary('+', js.string(""), pop())
            .withSourceInformation(node.sourceInformation));
      }
    } else {
      Element convertToString = backend.helpers.stringInterpolationHelper;
      registry.registerStaticUse(
          new StaticUse.staticInvoke(convertToString, CallStructure.ONE_ARG));
      js.Expression jsHelper =
          backend.emitter.staticFunctionAccess(convertToString);
      use(input);
      push(new js.Call(jsHelper, <js.Expression>[pop()],
          sourceInformation: node.sourceInformation));
    }
  }

  void visitLiteralList(HLiteralList node) {
    registry.registerInstantiatedClass(coreClasses.listClass);
    generateArrayLiteral(node);
  }

  void generateArrayLiteral(HLiteralList node) {
    List<js.Expression> elements = node.inputs.map((HInstruction input) {
      use(input);
      return pop();
    }).toList();
    push(new js.ArrayInitializer(elements)
        .withSourceInformation(node.sourceInformation));
  }

  void visitIndex(HIndex node) {
    use(node.receiver);
    js.Expression receiver = pop();
    use(node.index);
    push(new js.PropertyAccess(receiver, pop())
        .withSourceInformation(node.sourceInformation));
  }

  void visitIndexAssign(HIndexAssign node) {
    use(node.receiver);
    js.Expression receiver = pop();
    use(node.index);
    js.Expression index = pop();
    use(node.value);
    push(new js.Assignment(new js.PropertyAccess(receiver, index), pop())
        .withSourceInformation(node.sourceInformation));
  }

  void checkInt(HInstruction input, String cmp) {
    use(input);
    js.Expression left = pop();
    use(input);
    js.Expression or0 = new js.Binary("|", pop(), new js.LiteralNumber("0"));
    push(new js.Binary(cmp, left, or0));
  }

  void checkBigInt(
      HInstruction input, String cmp, SourceInformation sourceInformation) {
    use(input);
    js.Expression left = pop();
    use(input);
    js.Expression right = pop();
    // TODO(4984): Deal with infinity and -0.0.
    push(js.js('Math.floor(#) $cmp #',
        <js.Expression>[left, right]).withSourceInformation(sourceInformation));
  }

  void checkTypeOf(HInstruction input, String cmp, String typeName,
      SourceInformation sourceInformation) {
    use(input);
    js.Expression typeOf = new js.Prefix("typeof", pop());
    push(new js.Binary(cmp, typeOf, js.string(typeName)));
  }

  void checkNum(
      HInstruction input, String cmp, SourceInformation sourceInformation) {
    return checkTypeOf(input, cmp, 'number', sourceInformation);
  }

  void checkDouble(
      HInstruction input, String cmp, SourceInformation sourceInformation) {
    return checkNum(input, cmp, sourceInformation);
  }

  void checkString(
      HInstruction input, String cmp, SourceInformation sourceInformation) {
    return checkTypeOf(input, cmp, 'string', sourceInformation);
  }

  void checkBool(
      HInstruction input, String cmp, SourceInformation sourceInformation) {
    return checkTypeOf(input, cmp, 'boolean', sourceInformation);
  }

  void checkObject(
      HInstruction input, String cmp, SourceInformation sourceInformation) {
    assert(NullConstantValue.JsNull == 'null');
    if (cmp == "===") {
      checkTypeOf(input, '===', 'object', sourceInformation);
      js.Expression left = pop();
      use(input);
      js.Expression notNull = new js.Binary("!==", pop(), new js.LiteralNull());
      push(new js.Binary("&&", left, notNull)
          .withSourceInformation(sourceInformation));
    } else {
      assert(cmp == "!==");
      checkTypeOf(input, '!==', 'object', sourceInformation);
      js.Expression left = pop();
      use(input);
      js.Expression eqNull = new js.Binary("===", pop(), new js.LiteralNull());
      push(new js.Binary("||", left, eqNull)
          .withSourceInformation(sourceInformation));
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

  void checkFieldDoesNotExist(HInstruction input, String fieldName) {
    use(input);
    js.PropertyAccess field = new js.PropertyAccess.field(pop(), fieldName);
    push(new js.Prefix('!', field));
  }

  void checkImmutableArray(HInstruction input) {
    checkFieldExists(input, 'immutable\$list');
  }

  void checkMutableArray(HInstruction input) {
    checkFieldDoesNotExist(input, 'immutable\$list');
  }

  void checkExtendableArray(HInstruction input) {
    checkFieldDoesNotExist(input, 'fixed\$length');
  }

  void checkFixedArray(HInstruction input) {
    checkFieldExists(input, 'fixed\$length');
  }

  void checkNull(HInstruction input) {
    use(input);
    push(new js.Binary('==', pop(), new js.LiteralNull()));
  }

  void checkNonNull(HInstruction input) {
    use(input);
    push(new js.Binary('!=', pop(), new js.LiteralNull()));
  }

  void checkType(HInstruction input, HInstruction interceptor, DartType type,
      SourceInformation sourceInformation,
      {bool negative: false}) {
    Element element = type.element;
    if (element == helpers.jsArrayClass) {
      checkArray(input, negative ? '!==' : '===');
      return;
    } else if (element == helpers.jsMutableArrayClass) {
      if (negative) {
        checkImmutableArray(input);
      } else {
        checkMutableArray(input);
      }
      return;
    } else if (element == helpers.jsExtendableArrayClass) {
      if (negative) {
        checkFixedArray(input);
      } else {
        checkExtendableArray(input);
      }
      return;
    } else if (element == helpers.jsFixedArrayClass) {
      if (negative) {
        checkExtendableArray(input);
      } else {
        checkFixedArray(input);
      }
      return;
    } else if (element == helpers.jsUnmodifiableArrayClass) {
      if (negative) {
        checkMutableArray(input);
      } else {
        checkImmutableArray(input);
      }
      return;
    }
    if (interceptor != null) {
      checkTypeViaProperty(interceptor, type, sourceInformation,
          negative: negative);
    } else {
      checkTypeViaProperty(input, type, sourceInformation, negative: negative);
    }
  }

  void checkTypeViaProperty(
      HInstruction input, DartType type, SourceInformation sourceInformation,
      {bool negative: false}) {
    registry.registerTypeUse(new TypeUse.isCheck(type));

    use(input);

    js.PropertyAccess field =
        new js.PropertyAccess(pop(), backend.namer.operatorIsType(type))
            .withSourceInformation(sourceInformation);
    // We always negate at least once so that the result is boolified.
    push(new js.Prefix('!', field).withSourceInformation(sourceInformation));
    // If the result is not negated, put another '!' in front.
    if (!negative) {
      push(new js.Prefix('!', pop()).withSourceInformation(sourceInformation));
    }
  }

  void checkTypeViaInstanceof(
      HInstruction input, DartType type, SourceInformation sourceInformation,
      {bool negative: false}) {
    registry.registerTypeUse(new TypeUse.isCheck(type));

    use(input);

    js.Expression jsClassReference =
        backend.emitter.constructorAccess(type.element);
    push(js.js('# instanceof #',
        [pop(), jsClassReference]).withSourceInformation(sourceInformation));
    if (negative) {
      push(new js.Prefix('!', pop()).withSourceInformation(sourceInformation));
    }
    registry.registerInstantiation(type);
  }

  void handleNumberOrStringSupertypeCheck(
      HInstruction input,
      HInstruction interceptor,
      DartType type,
      SourceInformation sourceInformation,
      {bool negative: false}) {
    assert(!identical(type.element, coreClasses.listClass) &&
        !Elements.isListSupertype(type.element, compiler) &&
        !Elements.isStringOnlySupertype(type.element, compiler));
    String relation = negative ? '!==' : '===';
    checkNum(input, relation, sourceInformation);
    js.Expression numberTest = pop();
    checkString(input, relation, sourceInformation);
    js.Expression stringTest = pop();
    checkObject(input, relation, sourceInformation);
    js.Expression objectTest = pop();
    checkType(input, interceptor, type, sourceInformation, negative: negative);
    String combiner = negative ? '&&' : '||';
    String combiner2 = negative ? '||' : '&&';
    push(new js.Binary(
            combiner,
            new js.Binary(combiner, numberTest, stringTest)
                .withSourceInformation(sourceInformation),
            new js.Binary(combiner2, objectTest, pop())
                .withSourceInformation(sourceInformation))
        .withSourceInformation(sourceInformation));
  }

  void handleStringSupertypeCheck(HInstruction input, HInstruction interceptor,
      DartType type, SourceInformation sourceInformation,
      {bool negative: false}) {
    assert(!identical(type.element, coreClasses.listClass) &&
        !Elements.isListSupertype(type.element, compiler) &&
        !Elements.isNumberOrStringSupertype(type.element, compiler));
    String relation = negative ? '!==' : '===';
    checkString(input, relation, sourceInformation);
    js.Expression stringTest = pop();
    checkObject(input, relation, sourceInformation);
    js.Expression objectTest = pop();
    checkType(input, interceptor, type, sourceInformation, negative: negative);
    String combiner = negative ? '||' : '&&';
    push(new js.Binary(negative ? '&&' : '||', stringTest,
        new js.Binary(combiner, objectTest, pop())));
  }

  void handleListOrSupertypeCheck(HInstruction input, HInstruction interceptor,
      DartType type, SourceInformation sourceInformation,
      {bool negative: false}) {
    assert(!identical(type.element, coreClasses.stringClass) &&
        !Elements.isStringOnlySupertype(type.element, compiler) &&
        !Elements.isNumberOrStringSupertype(type.element, compiler));
    String relation = negative ? '!==' : '===';
    checkObject(input, relation, sourceInformation);
    js.Expression objectTest = pop();
    checkArray(input, relation);
    js.Expression arrayTest = pop();
    checkType(input, interceptor, type, sourceInformation, negative: negative);
    String combiner = negative ? '&&' : '||';
    push(new js.Binary(negative ? '||' : '&&', objectTest,
            new js.Binary(combiner, arrayTest, pop()))
        .withSourceInformation(sourceInformation));
  }

  void visitIs(HIs node) {
    emitIs(node, "===", node.sourceInformation);
  }

  void visitIsViaInterceptor(HIsViaInterceptor node) {
    emitIsViaInterceptor(node, node.sourceInformation, negative: false);
  }

  void emitIs(HIs node, String relation, SourceInformation sourceInformation) {
    DartType type = node.typeExpression;
    registry.registerTypeUse(new TypeUse.isCheck(type));
    HInstruction input = node.expression;

    // If this is changed to single == there are several places below that must
    // be changed to match.
    assert(relation == '===' || relation == '!==');
    bool negative = relation == '!==';

    if (node.isVariableCheck || node.isCompoundCheck) {
      use(node.checkCall);
      if (negative) push(new js.Prefix('!', pop()));
    } else {
      assert(node.isRawCheck);
      HInstruction interceptor = node.interceptor;
      ClassElement objectClass = coreClasses.objectClass;
      Element element = type.element;
      if (element == coreClasses.nullClass) {
        if (negative) {
          checkNonNull(input);
        } else {
          checkNull(input);
        }
      } else if (identical(element, objectClass) || type.treatAsDynamic) {
        // The constant folder also does this optimization, but we make
        // it safe by assuming it may have not run.
        push(newLiteralBool(!negative, sourceInformation));
      } else if (element == coreClasses.stringClass) {
        checkString(input, relation, sourceInformation);
      } else if (element == coreClasses.doubleClass) {
        checkDouble(input, relation, sourceInformation);
      } else if (element == coreClasses.numClass) {
        checkNum(input, relation, sourceInformation);
      } else if (element == coreClasses.boolClass) {
        checkBool(input, relation, sourceInformation);
      } else if (element == coreClasses.intClass) {
        // The is check in the code tells us that it might not be an
        // int. So we do a typeof first to avoid possible
        // deoptimizations on the JS engine due to the Math.floor check.
        checkNum(input, relation, sourceInformation);
        js.Expression numTest = pop();
        checkBigInt(input, relation, sourceInformation);
        push(new js.Binary(negative ? '||' : '&&', numTest, pop())
            .withSourceInformation(sourceInformation));
      } else if (node.useInstanceOf) {
        assert(interceptor == null);
        checkTypeViaInstanceof(input, type, sourceInformation,
            negative: negative);
      } else if (Elements.isNumberOrStringSupertype(element, compiler)) {
        handleNumberOrStringSupertypeCheck(
            input, interceptor, type, sourceInformation,
            negative: negative);
      } else if (Elements.isStringOnlySupertype(element, compiler)) {
        handleStringSupertypeCheck(input, interceptor, type, sourceInformation,
            negative: negative);
      } else if (identical(element, coreClasses.listClass) ||
          Elements.isListSupertype(element, compiler)) {
        handleListOrSupertypeCheck(input, interceptor, type, sourceInformation,
            negative: negative);
      } else if (type.isFunctionType) {
        checkType(input, interceptor, type, sourceInformation,
            negative: negative);
      } else if ((input.canBePrimitive(compiler) &&
              !input.canBePrimitiveArray(compiler)) ||
          input.canBeNull()) {
        checkObject(input, relation, node.sourceInformation);
        js.Expression objectTest = pop();
        checkType(input, interceptor, type, sourceInformation,
            negative: negative);
        push(new js.Binary(negative ? '||' : '&&', objectTest, pop())
            .withSourceInformation(sourceInformation));
      } else {
        checkType(input, interceptor, type, sourceInformation,
            negative: negative);
      }
    }
  }

  void emitIsViaInterceptor(
      HIsViaInterceptor node, SourceInformation sourceInformation,
      {bool negative: false}) {
    checkTypeViaProperty(
        node.interceptor, node.typeExpression, sourceInformation,
        negative: negative);
  }

  js.Expression generateReceiverOrArgumentTypeTest(
      HInstruction input, TypeMask checkedType) {
    ClosedWorld closedWorld = compiler.closedWorld;
    TypeMask inputType = input.instructionType;
    // Figure out if it is beneficial to turn this into a null check.
    // V8 generally prefers 'typeof' checks, but for integers and
    // indexable primitives we cannot compile this test into a single
    // typeof check so the null check is cheaper.
    bool isIntCheck = checkedType.containsOnlyInt(closedWorld);
    bool turnIntoNumCheck = isIntCheck && input.isIntegerOrNull(compiler);
    bool turnIntoNullCheck = !turnIntoNumCheck &&
        (checkedType.nullable() == inputType) &&
        (isIntCheck ||
            checkedType.satisfies(helpers.jsIndexableClass, closedWorld));

    if (turnIntoNullCheck) {
      use(input);
      return new js.Binary("==", pop(), new js.LiteralNull())
          .withSourceInformation(input.sourceInformation);
    } else if (isIntCheck && !turnIntoNumCheck) {
      // input is !int
      checkBigInt(input, '!==', input.sourceInformation);
      return pop();
    } else if (turnIntoNumCheck || checkedType.containsOnlyNum(closedWorld)) {
      // input is !num
      checkNum(input, '!==', input.sourceInformation);
      return pop();
    } else if (checkedType.containsOnlyBool(closedWorld)) {
      // input is !bool
      checkBool(input, '!==', input.sourceInformation);
      return pop();
    } else if (checkedType.containsOnlyString(closedWorld)) {
      // input is !string
      checkString(input, '!==', input.sourceInformation);
      return pop();
    }
    reporter.internalError(input, 'Unexpected check: $checkedType.');
    return null;
  }

  void visitTypeConversion(HTypeConversion node) {
    if (node.isArgumentTypeCheck || node.isReceiverTypeCheck) {
      ClosedWorld closedWorld = compiler.closedWorld;
      // An int check if the input is not int or null, is not
      // sufficient for doing an argument or receiver check.
      assert(compiler.options.trustTypeAnnotations ||
          !node.checkedType.containsOnlyInt(closedWorld) ||
          node.checkedInput.isIntegerOrNull(compiler));
      js.Expression test = generateReceiverOrArgumentTypeTest(
          node.checkedInput, node.checkedType);
      js.Block oldContainer = currentContainer;
      js.Statement body = new js.Block.empty();
      currentContainer = body;
      if (node.isArgumentTypeCheck) {
        generateThrowWithHelper(
            helpers.throwIllegalArgumentException, node.checkedInput,
            sourceInformation: node.sourceInformation);
      } else if (node.isReceiverTypeCheck) {
        use(node.checkedInput);
        js.Name methodName =
            backend.namer.invocationName(node.receiverTypeCheckSelector);
        js.Expression call = js.propertyCall(pop(), methodName, []);
        pushStatement(new js.Return(call));
      }
      currentContainer = oldContainer;
      body = unwrapStatement(body);
      pushStatement(new js.If.noElse(test, body)
          .withSourceInformation(node.sourceInformation));
      return;
    }

    assert(node.isCheckedModeCheck || node.isCastTypeCheck);
    DartType type = node.typeExpression;
    assert(type.kind != TypeKind.TYPEDEF);
    if (type.isFunctionType) {
      // TODO(5022): We currently generate $isFunction checks for
      // function types.
      registry.registerTypeUse(
          new TypeUse.isCheck(compiler.coreTypes.functionType));
    }
    registry.registerTypeUse(new TypeUse.isCheck(type));

    CheckedModeHelper helper;
    if (node.isBooleanConversionCheck) {
      helper = const CheckedModeHelper('boolConversionCheck');
    } else {
      helper =
          backend.getCheckedModeHelper(type, typeCast: node.isCastTypeCheck);
    }

    if (helper == null) {
      assert(type.isFunctionType);
      use(node.inputs[0]);
    } else {
      push(helper.generateCall(this, node));
    }
  }

  void visitTypeKnown(HTypeKnown node) {
    // [HTypeKnown] instructions are removed before generating code.
    assert(false);
  }

  void visitFunctionType(HFunctionType node) {
    FunctionType type = node.dartType;
    int inputCount = 0;
    use(node.inputs[inputCount++]);
    js.Expression returnType = pop();

    List<js.Expression> parameterTypes = <js.Expression>[];
    for (var _ in type.parameterTypes) {
      use(node.inputs[inputCount++]);
      parameterTypes.add(pop());
    }

    List<js.Expression> optionalParameterTypes = <js.Expression>[];
    for (var _ in type.optionalParameterTypes) {
      use(node.inputs[inputCount++]);
      optionalParameterTypes.add(pop());
    }

    List<js.Property> namedParameters = <js.Property>[];
    for (var _ in type.namedParameters) {
      use(node.inputs[inputCount++]);
      js.Expression name = pop();
      use(node.inputs[inputCount++]);
      namedParameters.add(new js.Property(name, pop()));
    }

    if (namedParameters.isEmpty) {
      var arguments = [returnType];
      if (!parameterTypes.isEmpty || !optionalParameterTypes.isEmpty) {
        arguments.add(new js.ArrayInitializer(parameterTypes));
      }
      if (!optionalParameterTypes.isEmpty) {
        arguments.add(new js.ArrayInitializer(optionalParameterTypes));
      }
      push(js.js('#(#)', [accessHelper('buildFunctionType'), arguments]));
    } else {
      var arguments = [
        returnType,
        new js.ArrayInitializer(parameterTypes),
        new js.ObjectInitializer(namedParameters)
      ];
      push(js.js('#(#)', [accessHelper('buildNamedFunctionType'), arguments]));
    }
  }

  void visitTypeInfoReadRaw(HTypeInfoReadRaw node) {
    use(node.inputs[0]);
    js.Expression receiver = pop();
    push(js.js(r'#.#', [receiver, backend.namer.rtiFieldName]));
  }

  void visitTypeInfoReadVariable(HTypeInfoReadVariable node) {
    TypeVariableElement element = node.variable.element;

    int index = element.index;
    HInstruction object = node.object;
    use(object);
    js.Expression receiver = pop();

    if (typeVariableAccessNeedsSubstitution(element, object.instructionType)) {
      js.Expression typeName =
          js.quoteName(backend.namer.runtimeTypeName(element.enclosingClass));
      Element helperElement = helpers.getRuntimeTypeArgument;
      registry.registerStaticUse(
          new StaticUse.staticInvoke(helperElement, CallStructure.THREE_ARGS));
      js.Expression helper =
          backend.emitter.staticFunctionAccess(helperElement);
      push(js.js(
          r'#(#, #, #)', [helper, receiver, typeName, js.js.number(index)]));
    } else {
      Element helperElement = helpers.getTypeArgumentByIndex;
      registry.registerStaticUse(
          new StaticUse.staticInvoke(helperElement, CallStructure.TWO_ARGS));
      js.Expression helper =
          backend.emitter.staticFunctionAccess(helperElement);
      push(js.js(r'#(#, #)', [helper, receiver, js.js.number(index)]));
    }
  }

  void visitTypeInfoExpression(HTypeInfoExpression node) {
    List<js.Expression> arguments = <js.Expression>[];
    for (HInstruction input in node.inputs) {
      use(input);
      arguments.add(pop());
    }

    switch (node.kind) {
      case TypeInfoExpressionKind.COMPLETE:
        int index = 0;
        js.Expression result = backend.rtiEncoder.getTypeRepresentation(
            node.dartType, (TypeVariableType variable) => arguments[index++]);
        assert(index == node.inputs.length);
        push(result);
        return;

      case TypeInfoExpressionKind.INSTANCE:
        // We expect only flat types for the INSTANCE representation.
        assert(
            node.dartType == (node.dartType.element as ClassElement).thisType);
        registry.registerInstantiatedClass(coreClasses.listClass);
        push(new js.ArrayInitializer(arguments)
            .withSourceInformation(node.sourceInformation));
    }
  }

  bool typeVariableAccessNeedsSubstitution(
      TypeVariableElement element, TypeMask receiverMask) {
    ClassElement cls = element.enclosingClass;
    ClosedWorld closedWorld = compiler.closedWorld;

    // See if the receiver type narrows the set of classes to ones that can be
    // indexed.
    // TODO(sra): Currently the only convenient query is [singleClass]. We
    // should iterate over all the concrete classes in [receiverMask].
    ClassElement receiverClass = receiverMask.singleClass(closedWorld);
    if (receiverClass != null) {
      if (backend.rti.isTrivialSubstitution(receiverClass, cls)) {
        return false;
      }
    }

    if (closedWorld.isUsedAsMixin(cls)) return true;

    return closedWorld.anyStrictSubclassOf(cls, (ClassElement subclass) {
      return !backend.rti.isTrivialSubstitution(subclass, cls);
    });
  }

  void visitReadTypeVariable(HReadTypeVariable node) {
    TypeVariableElement element = node.dartType.element;
    Element helperElement = helpers.convertRtiToRuntimeType;
    registry.registerStaticUse(
        new StaticUse.staticInvoke(helperElement, CallStructure.ONE_ARG));

    use(node.inputs[0]);
    if (node.hasReceiver) {
      if (backend.isInterceptorClass(element.enclosingClass)) {
        int index = element.index;
        js.Expression receiver = pop();
        js.Expression helper =
            backend.emitter.staticFunctionAccess(helperElement);
        js.Expression rtiFieldName = backend.namer.rtiFieldName;
        push(js.js(r'#(#.# && #.#[#])', [
          helper,
          receiver,
          rtiFieldName,
          receiver,
          rtiFieldName,
          js.js.number(index)
        ]));
      } else {
        backend.emitter.registerReadTypeVariable(element);
        push(js.js(
            '#.#()', [pop(), backend.namer.nameForReadTypeVariable(element)]));
      }
    } else {
      push(js.js('#(#)',
          [backend.emitter.staticFunctionAccess(helperElement), pop()]));
    }
  }

  void visitInterfaceType(HInterfaceType node) {
    List<js.Expression> typeArguments = <js.Expression>[];
    for (HInstruction type in node.inputs) {
      use(type);
      typeArguments.add(pop());
    }

    ClassElement cls = node.dartType.element;
    var arguments = [backend.emitter.typeAccess(cls)];
    if (!typeArguments.isEmpty) {
      arguments.add(new js.ArrayInitializer(typeArguments));
    }
    push(js.js('#(#)',
        [accessHelper('buildInterfaceType', arguments.length), arguments]));
  }

  void visitVoidType(HVoidType node) {
    push(js.js('#()', accessHelper('getVoidRuntimeType')));
  }

  void visitDynamicType(HDynamicType node) {
    push(js.js('#()', accessHelper('getDynamicRuntimeType')));
  }

  js.PropertyAccess accessHelper(String name, [int argumentCount = 0]) {
    Element helper = helpers.findHelper(name);
    if (helper == null) {
      // For mocked-up tests.
      return js.js('(void 0).$name');
    }
    registry.registerStaticUse(new StaticUse.staticInvoke(
        helper, new CallStructure.unnamed(argumentCount)));
    return backend.emitter.staticFunctionAccess(helper);
  }

  @override
  void visitRef(HRef node) {
    visit(node.value);
  }
}
