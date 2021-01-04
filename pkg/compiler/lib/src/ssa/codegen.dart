// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:collection' show Queue;

import 'package:front_end/src/api_unstable/dart2js.dart' show Link;

import '../common.dart';
import '../common/metrics.dart';
import '../common/names.dart';
import '../common/codegen.dart' show CodegenRegistry;
import '../common/tasks.dart' show Measurer, CompilerTask;
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../common_elements.dart' show JCommonElements;
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/interceptor_data.dart';
import '../js_backend/backend.dart' show CodegenInputs;
import '../js_backend/checked_mode_helpers.dart';
import '../js_backend/native_data.dart';
import '../js_backend/namer.dart' show ModularNamer;
import '../js_backend/runtime_types_codegen.dart';
import '../js_backend/runtime_types_new.dart'
    show RecipeEncoder, RecipeEncoding, indexTypeVariable;
import '../js_backend/specialized_checks.dart' show IsTestSpecialization;
import '../js_backend/type_reference.dart' show TypeReference;
import '../js_emitter/code_emitter_task.dart' show ModularEmitter;
import '../js_model/elements.dart' show JGeneratorBody;
import '../js_model/type_recipe.dart';
import '../native/behavior.dart';
import '../options.dart';
import '../tracer.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import '../universe/use.dart' show ConstantUse, DynamicUse, StaticUse, TypeUse;
import '../world.dart' show JClosedWorld;
import 'codegen_helpers.dart';
import 'nodes.dart';
import 'variable_allocator.dart';

abstract class CodegenPhase {
  String get name => '$runtimeType';
  void visitGraph(HGraph graph);
}

class SsaCodeGeneratorTask extends CompilerTask {
  final CompilerOptions _options;
  final SourceInformationStrategy sourceInformationStrategy;
  final _CodegenMetrics _metrics = _CodegenMetrics();

  SsaCodeGeneratorTask(
      Measurer measurer, this._options, this.sourceInformationStrategy)
      : super(measurer);

  @override
  String get name => 'SSA code generator';

  @override
  Metrics get metrics => _metrics;

  js.Fun buildJavaScriptFunction(bool needsAsyncRewrite, FunctionEntity element,
      List<js.Parameter> parameters, js.Block body) {
    js.Fun finish(js.AsyncModifier asyncModifier) {
      return new js.Fun(parameters, body, asyncModifier: asyncModifier)
          .withSourceInformation(sourceInformationStrategy
              .createBuilderForContext(element)
              .buildDeclaration(element));
    }

    if (needsAsyncRewrite) {
      return finish(element.asyncMarker.isAsync
          ? (element.asyncMarker.isYielding
              ? js.AsyncModifier.asyncStar
              : js.AsyncModifier.async)
          : (element.asyncMarker.isYielding
              ? js.AsyncModifier.syncStar
              : js.AsyncModifier.sync));
    } else {
      return finish(js.AsyncModifier.sync);
    }
  }

  js.Expression generateCode(
      MemberEntity member,
      HGraph graph,
      CodegenInputs codegen,
      JClosedWorld closedWorld,
      CodegenRegistry registry,
      ModularNamer namer,
      ModularEmitter emitter) {
    if (member.isField) {
      return generateLazyInitializer(
          member, graph, codegen, closedWorld, registry, namer, emitter);
    } else {
      return generateMethod(
          member, graph, codegen, closedWorld, registry, namer, emitter);
    }
  }

  js.Expression generateLazyInitializer(
      FieldEntity field,
      HGraph graph,
      CodegenInputs codegen,
      JClosedWorld closedWorld,
      CodegenRegistry registry,
      ModularNamer namer,
      ModularEmitter emitter) {
    return measure(() {
      codegen.tracer.traceGraph("codegen", graph);
      SourceInformation sourceInformation = sourceInformationStrategy
          .createBuilderForContext(field)
          .buildDeclaration(field);
      SsaCodeGenerator codeGenerator = SsaCodeGenerator(
          this,
          _options,
          _metrics,
          emitter,
          codegen.rtiSubstitutions,
          codegen.rtiRecipeEncoder,
          namer,
          codegen.tracer,
          closedWorld,
          registry);
      codeGenerator.visitGraph(graph);
      return new js.Fun(codeGenerator.parameters, codeGenerator.body)
          .withSourceInformation(sourceInformation);
    });
  }

  js.Expression generateMethod(
      FunctionEntity method,
      HGraph graph,
      CodegenInputs codegen,
      JClosedWorld closedWorld,
      CodegenRegistry registry,
      ModularNamer namer,
      ModularEmitter emitter) {
    return measure(() {
      if (method.asyncMarker != AsyncMarker.SYNC) {
        registry.registerAsyncMarker(method.asyncMarker);
      }
      SsaCodeGenerator codeGenerator = SsaCodeGenerator(
          this,
          _options,
          _metrics,
          emitter,
          codegen.rtiSubstitutions,
          codegen.rtiRecipeEncoder,
          namer,
          codegen.tracer,
          closedWorld,
          registry);
      codeGenerator.visitGraph(graph);
      codegen.tracer.traceGraph("codegen", graph);
      return buildJavaScriptFunction(graph.needsAsyncRewrite, method,
          codeGenerator.parameters, codeGenerator.body);
    });
  }
}

class _CodegenMetrics extends MetricsBase {
  int countHIf = 0;
  int countHIfConstant = 0;
  final countHInterceptor = CountMetric('count.HInterceptor');
  final countHInterceptorGet = CountMetric('count.HInterceptor.getInterceptor');
  final countHInterceptorOneshot = CountMetric('count.HInterceptor.oneShot');
  final countHInterceptorConditionalConstant =
      CountMetric('count.HInterceptor.conditionalConstant');

  _CodegenMetrics();

  @override
  String get namespace => 'codegen';

  @override
  Iterable<Metric> get primary => [];

  @override
  Iterable<Metric> get secondary => [
        CountMetric('count.HIf')..add(countHIf),
        CountMetric('count.HIf.constant')..add(countHIfConstant),
        countHInterceptor,
        countHInterceptorGet,
        countHInterceptorConditionalConstant,
        countHInterceptorOneshot
      ];
}

class SsaCodeGenerator implements HVisitor, HBlockInformationVisitor {
  /// Returned by [expressionType] to tell how code can be generated for
  /// a subgraph.
  /// - [TYPE_STATEMENT] means that the graph must be generated as a statement,
  /// which is always possible.
  /// - [TYPE_EXPRESSION] means that the graph can be generated as an expression,
  /// or possibly several comma-separated expressions.
  /// - [TYPE_DECLARATION] means that the graph can be generated as an
  /// expression, and that it only generates expressions of the form
  ///   variable = expression
  /// which are also valid as parts of a "var" declaration.
  static const int TYPE_STATEMENT = 0;
  static const int TYPE_EXPRESSION = 1;
  static const int TYPE_DECLARATION = 2;

  /// Whether we are currently generating expressions instead of statements.
  /// This includes declarations, which are generated as expressions.
  bool isGeneratingExpression = false;

  final CompilerTask _codegenTask;
  final CompilerOptions _options;
  final ModularEmitter _emitter;
  final RuntimeTypesSubstitutions _rtiSubstitutions;
  final RecipeEncoder _rtiRecipeEncoder;
  final ModularNamer _namer;
  final Tracer _tracer;
  final JClosedWorld _closedWorld;
  final CodegenRegistry _registry;
  final _CodegenMetrics _metrics;

  final Set<HInstruction> generateAtUseSite;
  final Set<HInstruction> controlFlowOperators;
  final Set<JumpTarget> breakAction;
  final Set<LabelDefinition> continueAction;
  final Set<JumpTarget> implicitContinueAction;
  final List<js.Parameter> parameters;

  js.Block currentContainer;
  js.Block get body => currentContainer;
  List<js.Expression> expressionStack;
  List<js.Block> oldContainerStack;

  /// Contains the names of the instructions, as well as the parallel
  /// copies to perform on block transitioning.
  VariableNames variableNames;

  /// `true` when we need to generate a `var` declaration at function entry,
  /// `false` if we can generate a `var` declaration at first assignment in the
  /// middle of the function.
  bool shouldGroupVarDeclarations = false;

  /// While generating expressions, we can't insert variable declarations.
  /// Instead we declare them at the start of the function.  When minifying
  /// we do this most of the time, because it reduces the size unless there
  /// is only one variable.
  final Set<String> collectedVariableDeclarations;

  /// Set of variables and parameters that have already been declared.
  final Set<String> declaredLocals;

  HGraph currentGraph;

  // Records a block-information that is being handled specially.
  // Used to break bad recursion.
  HBlockInformation currentBlockInformation;
  // The subgraph is used to delimit traversal for some constructions, e.g.,
  // if branches.
  SubGraph subGraph;

  // Pending blocks than need to be visited as part of current subgraph.
  Queue<HBasicBlock> blockQueue;

  SsaCodeGenerator(
      this._codegenTask,
      this._options,
      this._metrics,
      this._emitter,
      this._rtiSubstitutions,
      this._rtiRecipeEncoder,
      this._namer,
      this._tracer,
      this._closedWorld,
      this._registry,
      {SourceInformation sourceInformation})
      : declaredLocals = new Set<String>(),
        collectedVariableDeclarations = new Set<String>(),
        currentContainer = new js.Block.empty(),
        parameters = <js.Parameter>[],
        expressionStack = <js.Expression>[],
        oldContainerStack = <js.Block>[],
        generateAtUseSite = new Set<HInstruction>(),
        controlFlowOperators = new Set<HInstruction>(),
        breakAction = new Set<JumpTarget>(),
        continueAction = new Set<LabelDefinition>(),
        implicitContinueAction = new Set<JumpTarget>();

  JCommonElements get _commonElements => _closedWorld.commonElements;

  NativeData get _nativeData => _closedWorld.nativeData;

  InterceptorData get _interceptorData => _closedWorld.interceptorData;

  AbstractValueDomain get _abstractValueDomain =>
      _closedWorld.abstractValueDomain;

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

  // Returns the number of bits occupied by the value computed by [instruction].
  // Returns `32` if the value is negative or does not fit in a smaller number
  // of bits.
  int bitWidth(HInstruction instruction) {
    const int MAX = 32;
    int constant(HInstruction instruction) {
      if (instruction is HConstant && instruction.isConstantInteger()) {
        IntConstantValue constant = instruction.constant;
        return constant.intValue.toInt();
      }
      return null;
    }

    if (instruction.isConstantInteger()) {
      int value = constant(instruction);
      if (value < 0) return MAX;
      if (value > ((1 << 31) - 1)) return MAX;
      return value.bitLength;
    }
    if (instruction is HBitAnd) {
      return math.min(bitWidth(instruction.left), bitWidth(instruction.right));
    }
    if (instruction is HBitOr || instruction is HBitXor) {
      HBinaryBitOp bitOp = instruction;
      int leftWidth = bitWidth(bitOp.left);
      if (leftWidth == MAX) return MAX;
      return math.max(leftWidth, bitWidth(bitOp.right));
    }
    if (instruction is HShiftLeft) {
      int shiftCount = constant(instruction.right);
      if (shiftCount == null || shiftCount < 0 || shiftCount > 31) return MAX;
      int leftWidth = bitWidth(instruction.left);
      int width = leftWidth + shiftCount;
      return math.min(width, MAX);
    }
    if (instruction is HShiftRight) {
      int shiftCount = constant(instruction.right);
      if (shiftCount == null || shiftCount < 0 || shiftCount > 31) return MAX;
      int leftWidth = bitWidth(instruction.left);
      if (leftWidth >= MAX) return MAX;
      return math.max(leftWidth - shiftCount, 0);
    }
    if (instruction is HAdd) {
      return math.min(
          1 + math.max(bitWidth(instruction.left), bitWidth(instruction.right)),
          MAX);
    }
    return MAX;
  }

  bool requiresUintConversion(HInstruction instruction) {
    if (instruction.isUInt31(_abstractValueDomain).isDefinitelyTrue) {
      return false;
    }
    if (bitWidth(instruction) <= 31) return false;
    // If the result of a bit-operation is only used by other bit
    // operations, we do not have to convert to an unsigned integer.
    return hasNonBitOpUser(instruction, new Set<HPhi>());
  }

  /// If the [instruction] is not `null` it will be used to attach the position
  /// to the [statement].
  void pushStatement(js.Statement statement) {
    assert(expressionStack.isEmpty);
    currentContainer.statements.add(statement);
  }

  void insertStatementAtStart(js.Statement statement) {
    currentContainer.statements.insert(0, statement);
  }

  /// If the [instruction] is not `null` it will be used to attach the position
  /// to the [expression].
  pushExpressionAsStatement(
      js.Expression expression, SourceInformation sourceInformation) {
    pushStatement(new js.ExpressionStatement(expression)
        .withSourceInformation(sourceInformation));
  }

  /// If the [instruction] is not `null` it will be used to attach the position
  /// to the [expression].
  push(js.Expression expression) {
    expressionStack.add(expression);
  }

  js.Expression pop() {
    return expressionStack.removeLast();
  }

  void preGenerateMethod(HGraph graph) {
    void runPhase(CodegenPhase phase, {bool traceGraph = true}) {
      _codegenTask.measureSubtask(phase.name, () => phase.visitGraph(graph));
      if (traceGraph) {
        _tracer.traceGraph(phase.name, graph);
      }
      assert(graph.isValid(), 'Graph not valid after ${phase.name}');
    }

    runPhase(
        new SsaInstructionSelection(_options, _closedWorld, _interceptorData));
    runPhase(new SsaTypeKnownRemover());
    runPhase(new SsaTrustedCheckRemover(_options));
    runPhase(new SsaAssignmentChaining(_closedWorld));
    runPhase(new SsaInstructionMerger(_abstractValueDomain, generateAtUseSite));
    runPhase(new SsaConditionMerger(generateAtUseSite, controlFlowOperators));
    runPhase(new SsaShareRegionConstants());

    SsaLiveIntervalBuilder intervalBuilder =
        new SsaLiveIntervalBuilder(generateAtUseSite, controlFlowOperators);
    runPhase(intervalBuilder, traceGraph: false);
    SsaVariableAllocator allocator = new SsaVariableAllocator(
        _namer,
        intervalBuilder.liveInstructions,
        intervalBuilder.liveIntervals,
        generateAtUseSite);
    runPhase(allocator, traceGraph: false);
    variableNames = allocator.names;
    shouldGroupVarDeclarations = allocator.names.numberOfVariables > 1;
  }

  void handleDelayedVariableDeclarations(SourceInformation sourceInformation) {
    // Create 'var' list at the start of function.  Move assignment statements
    // from the top of the body into the variable initializers.
    if (collectedVariableDeclarations.isEmpty) return;

    List<js.VariableInitialization> declarations = [];
    List<js.Statement> statements = currentContainer.statements;
    int nextStatement = 0;

    while (nextStatement < statements.length) {
      if (collectedVariableDeclarations.isEmpty) break;
      js.Statement statement = statements[nextStatement];
      if (statement is js.ExpressionStatement) {
        js.Expression expression = statement.expression;
        if (expression is js.Assignment && !expression.isCompound) {
          js.Expression left = expression.leftHandSide;
          if (left is js.VariableReference) {
            String name = left.name;
            js.Expression value = expression.value;
            if (_safeInInitializer(value) &&
                collectedVariableDeclarations.remove(name)) {
              var initialization = new js.VariableInitialization(
                      new js.VariableDeclaration(name), value)
                  .withSourceInformation(expression.sourceInformation);
              declarations.add(initialization);
              ++nextStatement;
              continue;
            }
          }
        }
      }
      break;
    }

    List<js.VariableInitialization> uninitialized = [];
    for (String name in collectedVariableDeclarations) {
      uninitialized.add(new js.VariableInitialization(
          new js.VariableDeclaration(name), null));
    }
    var declarationList =
        new js.VariableDeclarationList(uninitialized + declarations)
            .withSourceInformation(sourceInformation);
    statements.replaceRange(
        0, nextStatement, [new js.ExpressionStatement(declarationList)]);
  }

  // An expression is safe to be pulled into a 'var' initializer if it does not
  // contain assignments to locals. We don't generate assignments to locals
  // inside expressions.
  bool _safeInInitializer(js.Expression node) => true;

  visitGraph(HGraph graph) {
    preGenerateMethod(graph);
    currentGraph = graph;
    visitSubGraph(new SubGraph(graph.entry, graph.exit));
    handleDelayedVariableDeclarations(graph.sourceInformation);
  }

  void visitSubGraph(SubGraph newSubGraph) {
    SubGraph oldSubGraph = subGraph;
    Queue<HBasicBlock> oldBlockQueue = blockQueue;
    subGraph = newSubGraph;
    blockQueue = new Queue<HBasicBlock>();
    enterSubGraph(subGraph.start);
    blockQueue = oldBlockQueue;
    subGraph = oldSubGraph;
  }

  /// Check whether a sub-graph can be generated as an expression, or even
  /// as a declaration, or if it has to fall back to being generated as
  /// a statement.
  /// Expressions are anything that doesn't generate control flow constructs.
  /// Declarations must only generate assignments on the form "id = expression",
  /// and not, e.g., expressions where the value isn't assigned, or where it's
  /// assigned to something that's not a simple variable.
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
        // HFieldSet generates code on the form "x.y = ...", which isn't valid
        // in a declaration.
        if (current.usedBy.isEmpty || current is HFieldSet) {
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

  /// Generate statements from block information.
  /// If the block information contains expressions, generate only
  /// assignments, and if it ends in a conditional branch, don't generate
  /// the condition.
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

  /// If the [block] only contains one statement returns that statement. If the
  /// that statement itself is a block, recursively calls this method.
  ///
  /// If the block is empty, returns a new instance of [js.NOP].
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

  /// Generate expressions from block information.
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

  /// Only visits the arguments starting at inputs[HInvoke.ARGUMENTS_OFFSET].
  List<js.Expression> visitArguments(List<HInstruction> inputs,
      {int start: HInvoke.ARGUMENTS_OFFSET}) {
    assert(inputs.length >= start);
    List<js.Expression> result = new List<js.Expression>.filled(inputs.length - start, null);
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

  js.Expression generateExpressionAssignment(String variableName,
      js.Expression value, SourceInformation sourceInformation) {
    // TODO(johnniwinther): Introduce a DeferredVariableUse to handle this
    // in the SSA codegen or let the JS printer handle it fully and remove it
    // here.
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
        js.Expression left = binary.left;
        if (left is js.VariableUse && left.name == variableName) {
          // We know now, that we can shorten x = x + y into x += y.
          // Also check for the shortcut where y equals 1: x++ and x--.
          js.Expression right = binary.right;
          if ((op == '+' || op == '-') &&
              right is js.LiteralNumber &&
              right.value == "1") {
            return new js.Prefix(op == '+' ? '++' : '--', left);
          }
          return new js.Assignment.compound(binary.left, op, binary.right);
        }
      }
    }
    return new js.Assignment(new js.VariableUse(variableName), value)
        .withSourceInformation(value.sourceInformation ?? sourceInformation);
  }

  void assignVariable(String variableName, js.Expression value,
      SourceInformation sourceInformation) {
    if (isGeneratingExpression) {
      // If we are in an expression then we can't declare the variable here.
      // We have no choice, but to use it and then declare it separately.
      if (!isVariableDeclared(variableName)) {
        collectedVariableDeclarations.add(variableName);
      }
      push(
          generateExpressionAssignment(variableName, value, sourceInformation));
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
          generateExpressionAssignment(variableName, value, sourceInformation),
          sourceInformation);
    }
  }

  void define(HInstruction instruction) {
    // For simple type checks like i = intTypeCheck(i), we don't have to
    // emit an assignment, because the intTypeCheck just returns its
    // argument.
    bool needsAssignment = true;
    if (instruction is HCheck) {
      if (instruction is HPrimitiveCheck ||
          instruction is HAsCheck ||
          instruction is HAsCheckSimple ||
          instruction is HBoolConversion ||
          instruction is HNullCheck) {
        String inputName = variableNames.getName(instruction.checkedInput);
        if (variableNames.getName(instruction) == inputName) {
          needsAssignment = false;
        }
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

  HInstruction skipGenerateAtUseCheckInputs(HCheck check) {
    HInstruction input = check.checkedInput;
    if (input is HCheck && isGenerateAtUseSite(input)) {
      return skipGenerateAtUseCheckInputs(input);
    }
    return input;
  }

  void use(HInstruction argument) {
    if (isGenerateAtUseSite(argument)) {
      visitExpression(argument);
    } else if (argument is HCheck && !variableNames.hasName(argument)) {
      // We have a check that is not generate-at-use and has no name, yet is a
      // subexpression (we are in 'use'). This happens when we have a chain of
      // checks on an available unnamed value (e.g. a constant). The checks are
      // generated as a statement, so we need to skip the generate-at-use check
      // tree to find the underlying value.

      // TODO(sra): We should ensure that this invariant holds: "every
      // instruction has a name or is generate-at-use". This would require
      // naming the input or output of the chain-of-checks.

      HCheck check = argument;
      // This can only happen if the checked node also does not have a name.
      assert(!variableNames.hasName(check.checkedInput));

      use(skipGenerateAtUseCheckInputs(check));
    } else {
      assert(variableNames.hasName(argument));
      push(js.VariableUse(variableNames.getName(argument)));
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
    pushStatement(new js.Break(_namer.continueLabelName(target)));
  }

  void implicitContinueAsBreak(JumpTarget target) {
    pushStatement(new js.Break(_namer.implicitContinueLabelName(target)));
  }

  void implicitBreakWithLabel(JumpTarget target) {
    pushStatement(new js.Break(_namer.implicitBreakLabelName(target)));
  }

  js.Statement wrapIntoLabels(
      js.Statement result, List<LabelDefinition> labels) {
    for (LabelDefinition label in labels) {
      if (label.isTarget) {
        String breakLabelString = _namer.breakLabelName(label);
        result = new js.LabeledStatement(breakLabelString, result);
      }
    }
    return result;
  }

  // The regular [visitIf] method implements the needed logic.
  @override
  bool visitIfInfo(HIfBlockInformation info) => false;

  @override
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
    bool handledDefault = false;
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

        // If this is the last statement, then these cases also belong to the
        // default block.
        if (statementIndex == info.statements.length - 1) {
          currentContainer = new js.Block.empty();
          cases.add(new js.Default(currentContainer));
          handledDefault = true;
        }

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
    if (info.statements.last.start.isLive && !handledDefault) {
      currentContainer = new js.Block.empty();
      generateStatements(info.statements.last);
      if (currentContainer.statements.isNotEmpty) {
        cases.add(new js.Default(currentContainer));
      }
    }

    currentContainer = oldContainer;

    js.Statement result =
        new js.Switch(key, cases).withSourceInformation(info.sourceInformation);
    pushStatement(wrapIntoLabels(result, info.labels));
    return true;
  }

  @override
  bool visitSequenceInfo(HStatementSequenceInformation info) {
    return false;
  }

  @override
  bool visitSubGraphInfo(HSubGraphBlockInformation info) {
    visitSubGraph(info.subGraph);
    return true;
  }

  @override
  bool visitSubExpressionInfo(HSubExpressionBlockInformation info) {
    return false;
  }

  @override
  bool visitAndOrInfo(HAndOrBlockInformation info) {
    return false;
  }

  @override
  bool visitTryInfo(HTryBlockInformation info) {
    js.Block body = generateStatementsInNewBlock(info.body);
    js.Catch catchPart = null;
    js.Block finallyPart = null;
    if (info.catchBlock != null) {
      void register(ClassEntity classElement) {
        if (classElement != null) {
          _registry
              // ignore:deprecated_member_use_from_same_package
              .registerInstantiatedClass(classElement);
        }
      }

      register(_commonElements.jsPlainJavaScriptObjectClass);
      register(_commonElements.jsUnknownJavaScriptObjectClass);

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

  @override
  bool visitLoopInfo(HLoopBlockInformation info) {
    HExpressionInformation condition = info.condition;
    bool isConditionExpression = isJSCondition(condition);

    js.Loop loop;

    switch (info.kind) {
      // Treat all three "test-first" loops the same way.
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
        failedAt(condition.conditionExpression,
            'Unexpected loop kind: ${info.kind}.');
    }
    js.Statement result = loop;
    if (info.kind == HLoopBlockInformation.SWITCH_CONTINUE_LOOP) {
      String continueLabelString =
          _namer.implicitContinueLabelName(info.target);
      result = new js.LabeledStatement(continueLabelString, result);
    }
    pushStatement(wrapIntoLabels(result, info.labels));
    return true;
  }

  @override
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
          String labelName = _namer.continueLabelName(label);
          result = new js.LabeledStatement(labelName, result);
          continueAction.add(label);
          continueOverrides = continueOverrides.prepend(label);
        }
      }
      // For handling unlabeled continues from the body of a loop.
      // TODO(lrn): Consider recording whether the target is in fact
      // a target of an unlabeled continue, and not generate this if it isn't.
      JumpTarget target = labeledBlockInfo.target;
      String labelName = _namer.implicitContinueLabelName(target);
      result = new js.LabeledStatement(labelName, result);
      implicitContinueAction.add(target);
      continueOverrides = continueOverrides.prepend(target);
    } else {
      for (LabelDefinition label in labeledBlockInfo.labels) {
        if (label.isBreakTarget) {
          String labelName = _namer.breakLabelName(label);
          result = new js.LabeledStatement(labelName, result);
        }
      }
    }
    JumpTarget target = labeledBlockInfo.target;
    if (target.isSwitch) {
      // This is an extra block around a switch that is generated
      // as a nested if/else chain. We add an extra break target
      // so that case code can break.
      String labelName = _namer.implicitBreakLabelName(target);
      result = new js.LabeledStatement(labelName, result);
      breakAction.add(target);
    }

    currentContainer = body;
    generateStatements(labeledBlockInfo.body);

    if (labeledBlockInfo.isContinue) {
      while (!continueOverrides.isEmpty) {
        continueAction.remove(continueOverrides.head);
        implicitContinueAction.remove(continueOverrides.head);
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
          String labelName = _namer.continueLabelName(label);
          result = new js.LabeledStatement(labelName, result);
          continueAction.add(label);
        }
      }
      String labelName = _namer.implicitContinueLabelName(target);
      result = new js.LabeledStatement(labelName, result);
      implicitContinueAction.add(info.target);
      visitBodyIgnoreLabels(info);
      implicitContinueAction.remove(info.target);
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
        continueSubGraph(continuation);
      }
    }
    return success;
  }

  void enterSubGraph(HBasicBlock node) {
    assert(blockQueue.isEmpty);
    assert(node != null);
    continueSubGraph(node);
    while (blockQueue.isNotEmpty) {
      node = blockQueue.removeFirst();
      assert(node.isLive);
      assert(subGraph.contains(node));

      // If this node has block-structure based information attached,
      // try using that to traverse from here.
      if (node.blockFlow != null && handleBlockFlow(node.blockFlow)) {
        continue;
      }

      iterateBasicBlock(node);
    }
  }

  void continueSubGraph(HBasicBlock node) {
    if (!node.isLive) return;
    // Don't follow edges out of the current sub-graph.
    if (!subGraph.contains(node)) return;
    blockQueue.add(node);
  }

  void emitAssignment(
      String destination, String source, SourceInformation sourceInformation) {
    assignVariable(destination, new js.VariableUse(source), sourceInformation);
  }

  /// Sequentialize a list of conceptually parallel copies. Parallel
  /// copies may contain cycles, that this method breaks.
  void sequentializeCopies(
      Iterable<Copy<HInstruction>> instructionCopies,
      String tempName,
      void doAssignment(
          String target, String source, SourceInformation sourceInformation)) {
    Map<String, SourceInformation> sourceInformationMap =
        <String, SourceInformation>{};

    // Map the instructions to strings.
    Iterable<Copy<String>> copies =
        instructionCopies.map((Copy<HInstruction> copy) {
      String sourceName = variableNames.getName(copy.source);
      sourceInformationMap[sourceName] = copy.source.sourceInformation;
      String destinationName = variableNames.getName(copy.destination);
      sourceInformationMap[sourceName] = copy.destination.sourceInformation;
      return new Copy<String>(sourceName, destinationName);
    });

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
    List<Copy<String>> prunedCopies = <Copy<String>>[];
    for (Copy<String> copy in copies) {
      if (copy.source != copy.destination) {
        prunedCopies.add(copy);
      }
    }
    copies = prunedCopies;

    // For each copy, set the current location of the source to
    // itself, and the initial value of the destination to the source.
    // Add the destination to the list of copies to make.
    for (Copy<String> copy in copies) {
      currentLocation[copy.source] = copy.source;
      initialValue[copy.destination] = copy.source;
      worklist.add(copy.destination);
    }

    // For each copy, if the destination does not have a current
    // location, then we can safely assign to it.
    for (Copy<String> copy in copies) {
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
        doAssignment(destination, copy,
            sourceInformationMap[copy] ?? sourceInformationMap[destination]);
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
        doAssignment(tempName, current, sourceInformationMap[current]);
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

    sequentializeCopies(
        handler.copies, variableNames.getSwapTemp(), emitAssignment);

    for (Copy<HInstruction> copy in handler.assignments) {
      String name = variableNames.getName(copy.destination);
      use(copy.source);
      assignVariable(name, pop(),
          copy.source.sourceInformation ?? copy.destination.sourceInformation);
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

  @override
  visitLateValue(HLateValue node) {
    use(node.target);
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

  @override
  visitIdentity(HIdentity node) {
    emitIdentityComparison(node, node.sourceInformation, inverse: false);
  }

  @override
  visitAdd(HAdd node) => visitInvokeBinary(node, '+');
  @override
  visitDivide(HDivide node) => visitInvokeBinary(node, '/');
  @override
  visitMultiply(HMultiply node) => visitInvokeBinary(node, '*');
  @override
  visitSubtract(HSubtract node) => visitInvokeBinary(node, '-');
  @override
  visitBitAnd(HBitAnd node) => visitBitInvokeBinary(node, '&');
  @override
  visitBitNot(HBitNot node) => visitBitInvokeUnary(node, '~');
  @override
  visitBitOr(HBitOr node) => visitBitInvokeBinary(node, '|');
  @override
  visitBitXor(HBitXor node) => visitBitInvokeBinary(node, '^');
  @override
  visitShiftLeft(HShiftLeft node) => visitBitInvokeBinary(node, '<<');
  @override
  visitShiftRight(HShiftRight node) => visitBitInvokeBinary(node, '>>>');

  @override
  visitTruncatingDivide(HTruncatingDivide node) {
    assert(node.isUInt31(_abstractValueDomain).isDefinitelyTrue);
    // TODO(karlklose): Enable this assertion again when type propagation is
    // fixed. Issue 23555.
//    assert(node.left.isUInt32(compiler));
    assert(node.right.isPositiveInteger(_abstractValueDomain).isDefinitelyTrue);
    use(node.left);
    js.Expression jsLeft = pop();
    use(node.right);
    push(new js.Binary('/', jsLeft, pop())
        .withSourceInformation(node.sourceInformation));
    push(new js.Binary('|', pop(), new js.LiteralNumber("0"))
        .withSourceInformation(node.sourceInformation));
  }

  @override
  visitRemainder(HRemainder node) {
    return visitInvokeBinary(node, '%');
  }

  @override
  visitNegate(HNegate node) => visitInvokeUnary(node, '-');

  @override
  visitAbs(HAbs node) {
    use(node.operand);
    push(js
        .js('Math.abs(#)', pop())
        .withSourceInformation(node.sourceInformation));
  }

  @override
  visitLess(HLess node) => visitRelational(node, '<');
  @override
  visitLessEqual(HLessEqual node) => visitRelational(node, '<=');
  @override
  visitGreater(HGreater node) => visitRelational(node, '>');
  @override
  visitGreaterEqual(HGreaterEqual node) => visitRelational(node, '>=');

  @override
  visitExit(HExit node) {
    // Don't do anything.
  }

  @override
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
      failedAt(node, 'dominated.length = ${dominated.length}');
    }
    if (dominated.length == 2 && block != currentGraph.entry) {
      failedAt(node, 'node.block != currentGraph.entry');
    }
    assert(dominated[0] == block.successors[0]);
    continueSubGraph(dominated.first);
  }

  @override
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

  @override
  visitBreak(HBreak node) {
    assert(node.block.successors.length == 1);
    if (node.label != null) {
      LabelDefinition label = node.label;
      if (breakAction.contains(label.target)) {
        implicitBreakWithLabel(label.target);
      } else {
        pushStatement(new js.Break(_namer.breakLabelName(label))
            .withSourceInformation(node.sourceInformation));
      }
    } else {
      JumpTarget target = node.target;
      if (breakAction.contains(target)) {
        implicitBreakWithLabel(target);
      } else {
        if (node.breakSwitchContinueLoop) {
          pushStatement(new js.Break(_namer.implicitContinueLabelName(target))
              .withSourceInformation(node.sourceInformation));
        } else {
          pushStatement(
              new js.Break(null).withSourceInformation(node.sourceInformation));
        }
      }
    }
  }

  @override
  visitContinue(HContinue node) {
    assert(node.block.successors.length == 1);
    if (node.label != null) {
      LabelDefinition label = node.label;
      if (continueAction.contains(label)) {
        continueAsBreak(label);
      } else {
        // TODO(floitsch): should this really be the breakLabelName?
        pushStatement(new js.Continue(_namer.breakLabelName(label))
            .withSourceInformation(node.sourceInformation));
      }
    } else {
      JumpTarget target = node.target;
      if (implicitContinueAction.contains(target)) {
        implicitContinueAsBreak(target);
      } else {
        if (target.isSwitch) {
          pushStatement(
              new js.Continue(_namer.implicitContinueLabelName(target))
                  .withSourceInformation(node.sourceInformation));
        } else {
          pushStatement(new js.Continue(null)
              .withSourceInformation(node.sourceInformation));
        }
      }
    }
  }

  @override
  visitExitTry(HExitTry node) {
    // An [HExitTry] is used to represent the control flow graph of a
    // try/catch block, ie the try body is always a predecessor
    // of the catch and finally. Here, we continue visiting the try
    // body by visiting the block that contains the user-level control
    // flow instruction.
    continueSubGraph(node.bodyTrySuccessor);
  }

  @override
  visitTry(HTry node) {
    // We should never get here. Try/catch/finally is always handled using block
    // information in [visitTryInfo].
    failedAt(node, 'visitTry should not be called.');
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
    continueSubGraph(node.joinBlock);
    return true;
  }

  void generateIf(HIf node, HIfBlockInformation info) {
    HStatementInformation thenGraph = info.thenGraph;
    HStatementInformation elseGraph = info.elseGraph;
    HInstruction condition = node.inputs.single;

    js.Expression test;
    js.Statement thenPart;
    js.Statement elsePart;

    HBasicBlock thenBlock = node.block.successors[0];
    // If we believe we will generate S1 as empty, instead of
    //
    //     if (e) S1; else S2;
    //
    // try to generate
    //
    //     if (!e) S2; else S1;
    //
    // It is better to generate `!e` rather than try and negate it later.
    // Recognize a single then-block with no code and no controlled phis.
    if (isGenerateAtUseSite(condition) &&
        thenBlock.successors.length == 1 &&
        thenBlock.successors.single == node.joinBlock &&
        node.joinBlock.phis.isEmpty &&
        thenBlock.first is HGoto) {
      generateNot(condition, condition.sourceInformation);
      test = pop();
      // Swap branches but visit in same order as register allocator.
      elsePart = unwrapStatement(generateStatementsInNewBlock(thenGraph));
      thenPart = unwrapStatement(generateStatementsInNewBlock(elseGraph));
      assert(elsePart is js.EmptyStatement);
    } else {
      use(condition);
      test = pop();
      thenPart = unwrapStatement(generateStatementsInNewBlock(thenGraph));
      elsePart = unwrapStatement(generateStatementsInNewBlock(elseGraph));
    }

    js.Statement code = _assembleIfThenElse(test, thenPart, elsePart);
    pushStatement(code.withSourceInformation(node.sourceInformation));
  }

  js.Statement _assembleIfThenElse(
      js.Expression test, js.Statement thenPart, js.Statement elsePart) {
    // Peephole rewrites:
    //
    //     if (e); else S;   -->   if (!e) S;
    //
    //     if (e);   -->   e;
    //
    // TODO(sra): We might be able to do better with reshaping the CFG.
    if (thenPart is js.EmptyStatement) {
      if (elsePart is js.EmptyStatement) {
        return js.ExpressionStatement(test);
      }
      test = js.Prefix('!', test);
      var temp = thenPart;
      thenPart = elsePart;
      elsePart = temp;
    }

    if (_options.experimentToBoolean) {
      if (elsePart is js.EmptyStatement &&
          thenPart is js.ExpressionStatement &&
          thenPart.expression is js.Call) {
        return js.ExpressionStatement(
            js.Binary('&&', test, thenPart.expression));
      }
    }

    return js.If(test, thenPart, elsePart);
  }

  @override
  visitIf(HIf node) {
    _metrics.countHIf++;
    HInstruction condition = node.inputs[0];
    if (condition.isConstant()) _metrics.countHIfConstant++;

    if (tryControlFlowOperation(node)) return;

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
      continueSubGraph(joinBlock);
    }

    // Visit all the dominated blocks that are not part of the then or else
    // branches, and is not the join block.
    // Depending on how the then/else branches terminate
    // (e.g., return/throw/break) there can be any number of these.
    List<HBasicBlock> dominated = node.block.dominatedBlocks;
    for (int i = 2; i < dominated.length; i++) {
      continueSubGraph(dominated[i]);
    }
  }

  @override
  void visitInterceptor(HInterceptor node) {
    _metrics.countHInterceptor.add();
    if (node.isConditionalConstantInterceptor) {
      _metrics.countHInterceptorConditionalConstant.add();
      assert(node.inputs.length == 2);
      use(node.receiver);
      js.Expression receiverExpression = pop();
      use(node.conditionalConstantInterceptor);
      js.Expression constant = pop();
      push(js.js('# && #', [receiverExpression, constant]));
    } else {
      _metrics.countHInterceptorGet.add();
      assert(node.inputs.length == 1);
      _registry.registerSpecializedGetInterceptor(node.interceptedClasses);
      js.Name name = _namer.nameForGetInterceptor(node.interceptedClasses);
      js.Expression isolate = _namer
          .readGlobalObjectForLibrary(_commonElements.interceptorsLibrary);
      use(node.receiver);
      List<js.Expression> arguments = <js.Expression>[pop()];
      push(js
          .propertyCall(isolate, name, arguments)
          .withSourceInformation(node.sourceInformation));
      _registry.registerUseInterceptor();
    }
  }

  @override
  visitInvokeDynamicMethod(HInvokeDynamicMethod node) {
    use(node.receiver);
    js.Expression object = pop();
    String methodName;
    List<js.Expression> arguments = visitArguments(node.inputs);
    MemberEntity target = node.element;

    // TODO(herhut): The namer should return the appropriate backendname here.
    if (target != null && !node.isInterceptedCall) {
      if (target == _commonElements.jsArrayAdd) {
        methodName = 'push';
      } else if (target == _commonElements.jsArrayRemoveLast) {
        methodName = 'pop';
      } else if (_commonElements.isJsStringSplit(target)) {
        methodName = 'split';
        // Split returns a List, so we make sure the backend knows the
        // list class is instantiated.
        _registry
            // ignore:deprecated_member_use_from_same_package
            .registerInstantiatedClass(_commonElements.listClass);
      }
    }

    js.Name methodLiteral;
    if (methodName == null) {
      methodLiteral = _namer.invocationName(node.selector);
      registerMethodInvoke(node);
    } else {
      methodLiteral = _namer.asName(methodName);
    }
    push(js
        .propertyCall(object, methodLiteral, arguments)
        .withSourceInformation(node.sourceInformation));
  }

  @override
  void visitInvokeConstructorBody(HInvokeConstructorBody node) {
    use(node.inputs[0]);
    js.Expression object = pop();
    js.Name methodName = _namer.instanceMethodName(node.element);
    List<js.Expression> arguments = visitArguments(node.inputs);
    push(js
        .propertyCall(object, methodName, arguments)
        .withSourceInformation(node.sourceInformation));
    _registry.registerStaticUse(new StaticUse.constructorBodyInvoke(
        node.element, new CallStructure.unnamed(arguments.length)));
  }

  @override
  void visitInvokeGeneratorBody(HInvokeGeneratorBody node) {
    JGeneratorBody element = node.element;
    if (element.isInstanceMember) {
      use(node.inputs[0]);
      js.Expression object = pop();
      List<js.Expression> arguments = visitArguments(node.inputs);
      js.Name methodName = _namer.instanceMethodName(element);
      push(js
          .propertyCall(object, methodName, arguments)
          .withSourceInformation(node.sourceInformation));
    } else {
      push(_emitter.staticFunctionAccess(element));
      List<js.Expression> arguments = visitArguments(node.inputs, start: 0);
      push(new js.Call(pop(), arguments,
          sourceInformation: node.sourceInformation));
    }

    _registry
        .registerStaticUse(new StaticUse.generatorBodyInvoke(node.element));
  }

  @override
  void visitOneShotInterceptor(HOneShotInterceptor node) {
    _metrics.countHInterceptor.add();
    _metrics.countHInterceptorOneshot.add();
    List<js.Expression> arguments = visitArguments(node.inputs);
    js.Expression isolate =
        _namer.readGlobalObjectForLibrary(_commonElements.interceptorsLibrary);
    Selector selector = node.selector;
    Set<ClassEntity> classes =
        _interceptorData.getInterceptedClassesOn(selector.name, _closedWorld);
    _registry.registerOneShotInterceptor(selector);
    js.Name methodName = _namer.nameForOneShotInterceptor(selector, classes);
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
    _registry.registerUseInterceptor();
  }

  AbstractValue getOptimizedSelectorFor(
      HInvokeDynamic node, Selector selector, AbstractValue mask) {
    if (node.element != null) {
      // Create an artificial type mask to make sure only
      // [node.element] will be enqueued. We're not using the receiver
      // type because our optimizations might end up in a state where the
      // invoke dynamic knows more than the receiver.
      ClassEntity enclosing = node.element.enclosingClass;
      if (_closedWorld.classHierarchy.isInstantiated(enclosing)) {
        return _abstractValueDomain.createNonNullExact(enclosing);
      } else {
        // The element is mixed in so a non-null subtype mask is the most
        // precise we have.
        assert(
            _closedWorld.isUsedAsMixin(enclosing),
            failedAt(
                node,
                "Element ${node.element} from $enclosing expected "
                "to be mixed in."));
        return _abstractValueDomain.createNonNullSubtype(enclosing);
      }
    }
    return mask ?? _abstractValueDomain.dynamicType;
  }

  void registerMethodInvoke(HInvokeDynamic node) {
    Selector selector = node.selector;

    // If we don't know what we're calling or if we are calling a getter,
    // we need to register that fact that we may be calling a closure
    // with the same arguments.
    MemberEntity target = node.element;
    if ((target == null || target.isGetter) &&
        // TODO(johnniwinther): Remove this when kernel adds an `isFunctionCall`
        // flag to [ir.MethodInvocation]. Currently we can't tell the difference
        // between a dynamic call and a function call, but we at least know that
        // toString is not a getter (a potential function call should otherwise
        // have been register for string concatenation).
        selector != Selectors.toString_) {
      // TODO(kasperl): If we have a typed selector for the call, we
      // may know something about the types of closures that need
      // the specific closure call method.
      Selector call = new Selector.callClosureFrom(selector);
      _registry
          .registerDynamicUse(new DynamicUse(call, null, node.typeArguments));
    }
    if (target != null) {
      // This is a dynamic invocation which we have found to have a single
      // target but for some reason haven't inlined. We are _still_ accessing
      // the target dynamically but we don't need to enqueue more than target
      // for this to work.
      assert(selector.applies(target),
          failedAt(node, '$selector does not apply to $target'));
      assert(!selector.isGetter && !selector.isSetter,
          "Unexpected direct invocation selector: $selector.");
      _registry.registerStaticUse(new StaticUse.directInvoke(
          target, selector.callStructure, node.typeArguments));
    } else {
      AbstractValue mask =
          getOptimizedSelectorFor(node, selector, node.receiverType);
      _registry.registerDynamicUse(
          new DynamicUse(selector, mask, node.typeArguments));
    }
  }

  void registerSetter(HInvokeDynamic node, {bool needsCheck: false}) {
    if (node.element is FieldEntity && !needsCheck) {
      // This is a dynamic update which we have found to have a single
      // target but for some reason haven't inlined. We are _still_ accessing
      // the target dynamically but we don't need to enqueue more than target
      // for this to work.
      _registry.registerStaticUse(new StaticUse.directSet(node.element));
    } else {
      Selector selector = node.selector;
      AbstractValue mask =
          getOptimizedSelectorFor(node, selector, node.receiverType);
      _registry.registerDynamicUse(
          new DynamicUse(selector, mask, node.typeArguments));
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
      _registry.registerStaticUse(new StaticUse.directGet(node.element));
    } else {
      Selector selector = node.selector;
      AbstractValue mask =
          getOptimizedSelectorFor(node, selector, node.receiverType);
      _registry.registerDynamicUse(
          new DynamicUse(selector, mask, node.typeArguments));
    }
  }

  @override
  visitInvokeDynamicSetter(HInvokeDynamicSetter node) {
    use(node.receiver);
    js.Name name = _namer.invocationName(node.selector);
    push(js
        .propertyCall(pop(), name, visitArguments(node.inputs))
        .withSourceInformation(node.sourceInformation));
    registerSetter(node, needsCheck: node.needsCheck);
  }

  @override
  visitInvokeDynamicGetter(HInvokeDynamicGetter node) {
    use(node.receiver);
    js.Name name = _namer.invocationName(node.selector);
    push(js
        .propertyCall(pop(), name, visitArguments(node.inputs))
        .withSourceInformation(node.sourceInformation));
    registerGetter(node);
  }

  @override
  visitInvokeClosure(HInvokeClosure node) {
    Selector call = new Selector.callClosureFrom(node.selector);
    use(node.receiver);
    push(js
        .propertyCall(
            pop(), _namer.invocationName(call), visitArguments(node.inputs))
        .withSourceInformation(node.sourceInformation));
    // TODO(kasperl): If we have a typed selector for the call, we
    // may know something about the types of closures that need
    // the specific closure call method.
    _registry
        .registerDynamicUse(new DynamicUse(call, null, node.typeArguments));
  }

  @override
  visitInvokeStatic(HInvokeStatic node) {
    MemberEntity element = node.element;
    node.instantiatedTypes?.forEach(_registry.registerInstantiation);

    List<js.Expression> arguments = visitArguments(node.inputs, start: 0);

    if (element == _commonElements.jsAllowInterop1 ||
        element == _commonElements.jsAllowInterop2) {
      _nativeData.registerAllowInterop();
    }

    if (_commonElements.isCheckConcurrentModificationError(element)) {
      // Manually inline the [checkConcurrentModificationError] function.  This
      // function is only called from a for-loop update.  Ideally we would just
      // generate the conditionalcontrol flow in the builder but it adds basic
      // blocks in the loop update that interfere with other optimizations and
      // confuses loop recognition.

      assert(arguments.length == 2);
      FunctionEntity throwFunction =
          _commonElements.throwConcurrentModificationError;
      _registry.registerStaticUse(
          new StaticUse.staticInvoke(throwFunction, CallStructure.ONE_ARG));

      // Calling using `(0, #)(#)` instead of `#(#)` separates the property load
      // of the static function access from the call.  For some reason this
      // helps V8 see that the call never happens so V8 makes the call a
      // deoptimization. This removes the call from the optimized loop, making
      // more optimizations available to the loop.  This form is 50% faster on
      // some small loop, almost as fast as loops with no concurrent
      // modification check.

      // Create [right] as a separate JS node to give the call a source
      // location.
      js.Expression right = js.js('(0, #)(#)', [
        _emitter.staticFunctionAccess(throwFunction),
        arguments[1]
      ]).withSourceInformation(node.sourceInformation);
      push(js.js('# || #', [arguments[0], right]).withSourceInformation(
          node.sourceInformation));
    } else {
      StaticUse staticUse;
      if (element.isConstructor) {
        CallStructure callStructure = new CallStructure.unnamed(
            arguments.length, node.typeArguments.length);
        staticUse = new StaticUse.constructorInvoke(element, callStructure);
      } else if (element.isGetter) {
        staticUse = new StaticUse.staticGet(element);
      } else if (element.isSetter) {
        staticUse = new StaticUse.staticSet(element);
      } else {
        assert(element.isFunction);
        CallStructure callStructure = new CallStructure.unnamed(
            arguments.length, node.typeArguments.length);
        staticUse = new StaticUse.staticInvoke(
            element, callStructure, node.typeArguments);
      }
      _registry.registerStaticUse(staticUse);
      push(_emitter.staticFunctionAccess(element));
      push(new js.Call(pop(), arguments,
          sourceInformation: node.sourceInformation));
    }
  }

  @override
  visitInvokeSuper(HInvokeSuper node) {
    MemberEntity superElement = node.element;
    ClassEntity superClass = superElement.enclosingClass;
    Selector selector = node.selector;
    bool useAliasedSuper = canUseAliasedSuperMember(superElement, selector);
    if (selector.isGetter) {
      if (superElement.isField || superElement.isGetter) {
        _registry.registerStaticUse(new StaticUse.superGet(superElement));
      } else {
        _registry.registerStaticUse(new StaticUse.superTearOff(node.element));
      }
    } else if (selector.isSetter) {
      if (superElement.isField) {
        _registry.registerStaticUse(new StaticUse.superFieldSet(superElement));
      } else {
        assert(superElement.isSetter);
        _registry.registerStaticUse(new StaticUse.superSetterSet(superElement));
      }
    } else {
      if (useAliasedSuper) {
        _registry.registerStaticUse(new StaticUse.superInvoke(
            superElement, new CallStructure.unnamed(node.inputs.length)));
      } else {
        _registry.registerStaticUse(new StaticUse.superInvoke(
            superElement, new CallStructure.unnamed(node.inputs.length - 1)));
      }
    }

    if (superElement.isField) {
      // TODO(sra): We can lower these in the simplifier.
      js.Name fieldName = _namer.instanceFieldPropertyName(superElement);
      use(node.getDartReceiver(_closedWorld));
      js.PropertyAccess access = new js.PropertyAccess(pop(), fieldName)
          .withSourceInformation(node.sourceInformation);
      if (node.isSetter) {
        use(node.value);
        push(new js.Assignment(access, pop())
            .withSourceInformation(node.sourceInformation));
      } else {
        push(access);
      }
    } else {
      if (!useAliasedSuper) {
        js.Name methodName;
        if (selector.isGetter && !superElement.isGetter) {
          // If this is a tear-off, register the fact that a tear-off closure
          // will be created, and that this tear-off must bypass ordinary
          // dispatch to ensure the super method is invoked.
          FunctionEntity helper = _commonElements.closureFromTearOff;
          _registry.registerStaticUse(new StaticUse.staticInvoke(
              helper,
              new CallStructure.unnamed(
                  node.inputs.length, node.typeArguments.length),
              node.typeArguments));
          methodName = _namer.invocationName(selector);
        } else {
          methodName = _namer.instanceMethodName(superElement);
        }

        push(js.js('#.#.call(#)', [
          _emitter.prototypeAccess(superClass, hasBeenInstantiated: true),
          methodName,
          visitArguments(node.inputs, start: 0)
        ]).withSourceInformation(node.sourceInformation));
      } else {
        use(node.receiver);
        push(js.js('#.#(#)', [
          pop(),
          _namer.aliasedSuperMemberPropertyName(superElement),
          visitArguments(node.inputs, start: 1)
        ]) // Skip receiver argument.
            .withSourceInformation(node.sourceInformation));
      }
    }
  }

  js.Expression _loadField(js.Expression receiver, FieldEntity field,
      SourceInformation sourceInformation) {
    _registry.registerStaticUse(StaticUse.fieldGet(field));
    js.Name name = _namer.instanceFieldPropertyName(field);
    return js.PropertyAccess(receiver, name)
        .withSourceInformation(sourceInformation);
  }

  @override
  visitFieldGet(HFieldGet node) {
    use(node.receiver);
    push(_loadField(pop(), node.element, node.sourceInformation));
  }

  @override
  visitFieldSet(HFieldSet node) {
    FieldEntity element = node.element;
    _registry.registerStaticUse(new StaticUse.fieldSet(element));
    js.Name name = _namer.instanceFieldPropertyName(element);
    use(node.receiver);
    js.Expression receiver = pop();
    use(node.value);
    push(new js.Assignment(
            new js.PropertyAccess(receiver, name)
                .withSourceInformation(node.sourceInformation),
            pop())
        .withSourceInformation(node.sourceInformation));
  }

  @override
  visitGetLength(HGetLength node) {
    use(node.receiver);
    push(new js.PropertyAccess.field(pop(), 'length')
        .withSourceInformation(node.sourceInformation));
  }

  @override
  visitReadModifyWrite(HReadModifyWrite node) {
    FieldEntity element = node.element;
    _registry.registerStaticUse(new StaticUse.fieldGet(element));
    _registry.registerStaticUse(new StaticUse.fieldSet(element));
    js.Name name = _namer.instanceFieldPropertyName(element);
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

  @override
  visitFunctionReference(HFunctionReference node) {
    FunctionEntity element = node.element;
    _registry.registerStaticUse(StaticUse.implicitInvoke(element));
    push(_emitter.staticFunctionAccess(element));
  }

  @override
  visitLocalGet(HLocalGet node) {
    use(node.receiver);
  }

  @override
  visitLocalSet(HLocalSet node) {
    use(node.value);
    assignVariable(
        variableNames.getName(node.receiver), pop(), node.sourceInformation);
  }

  @override
  visitInvokeExternal(HInvokeExternal node) {
    FunctionEntity target = node.element;
    List<HInstruction> inputs = node.inputs;

    assert(_nativeData.isNativeMember(target), 'non-native target: $node');

    String targetName = _nativeData.hasFixedBackendName(target)
        ? _nativeData.getFixedBackendName(target)
        : target.name;

    void invokeWithJavaScriptReceiver(js.Expression receiverExpression) {
      // JS-interop target names can be paths ("a.b"), so we parse them to
      // re-associate the property accesses ("#.a.b" is `dot(dot(#,'a'),'b')`).
      //
      // Native target names are simple identifiers, so re-parsing is not
      // necessary, but it is simpler to use the same code.
      String template;
      List templateInputs;
      if (target.isGetter) {
        template = '#.$targetName';
        templateInputs = [receiverExpression];
      } else if (target.isSetter) {
        assert(inputs.length == (target.isInstanceMember ? 2 : 1));
        use(inputs.last);
        template = '#.$targetName = #';
        templateInputs = [receiverExpression, pop()];
      } else {
        var arguments =
            visitArguments(inputs, start: target.isInstanceMember ? 1 : 0);
        template =
            target.isConstructor ? 'new #.$targetName(#)' : '#.$targetName(#)';
        templateInputs = [receiverExpression, arguments];
      }
      js.Expression expression = js.js
          .uncachedExpressionTemplate(template)
          .instantiate(templateInputs);
      push(expression.withSourceInformation(node.sourceInformation));
      _registry.registerNativeMethod(target);
    }

    if (_nativeData.isJsInteropMember(target)) {
      if (target.isStatic || target.isTopLevel || target.isConstructor) {
        String path = _nativeData.getFixedBackendMethodPath(target);
        js.Expression pathExpression =
            js.js.uncachedExpressionTemplate(path).instantiate([]);
        invokeWithJavaScriptReceiver(pathExpression);
        return;
      }
    }

    if (_nativeData.isNativeMember(target)) {
      _registry.registerNativeBehavior(node.nativeBehavior);
      if (target.isInstanceMember) {
        HInstruction receiver = inputs.first;
        use(receiver);
        invokeWithJavaScriptReceiver(pop());
        return;
      }
      if (target.isStatic || target.isTopLevel) {
        var arguments = visitArguments(inputs, start: 0);
        js.Expression targeExpression =
            js.js.uncachedExpressionTemplate(targetName).instantiate([]);
        js.Expression expression;
        if (target.isGetter) {
          expression = targeExpression;
        } else if (target.isSetter) {
          expression = js.js('# = #', [targeExpression, inputs.single]);
        } else {
          assert(target.isFunction);
          expression = js.js('#(#)', [targeExpression, arguments]);
        }
        push(expression.withSourceInformation(node.sourceInformation));
        _registry.registerNativeMethod(target);
        return;
      }

      failedAt(node, 'codegen not implemented (non-instance-member): $node');
    }
    failedAt(node, 'unexpected target: $node');
  }

  void registerForeignTypes(HForeign node) {
    NativeBehavior nativeBehavior = node.nativeBehavior;
    if (nativeBehavior == null) return;
    _registry.registerNativeBehavior(nativeBehavior);
  }

  @override
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

  @override
  visitCreate(HCreate node) {
    js.Expression jsClassReference = _emitter.constructorAccess(node.element);
    List<js.Expression> arguments = visitArguments(node.inputs, start: 0);
    push(new js.New(jsClassReference, arguments)
        .withSourceInformation(node.sourceInformation));
    // We also use HCreate to instantiate closure classes that belong to
    // function expressions. We have to register their use here, as otherwise
    // code for them might not be emitted.
    if (node.element.isClosure) {
      _registry
          // ignore:deprecated_member_use_from_same_package
          .registerInstantiatedClass(node.element);
    }
    node.instantiatedTypes?.forEach(_registry.registerInstantiation);
    if (node.callMethod != null) {
      _registry
          ?.registerStaticUse(new StaticUse.implicitInvoke(node.callMethod));
      _registry?.registerInstantiatedClosure(node.callMethod);
    }
  }

  @override
  visitCreateBox(HCreateBox node) {
    push(new js.ObjectInitializer(<js.Property>[]));
  }

  js.Expression newLiteralBool(
      bool value, SourceInformation sourceInformation) {
    if (_options.enableMinification) {
      // Use !0 for true, !1 for false.
      return new js.Prefix("!", new js.LiteralNumber(value ? "0" : "1"))
          .withSourceInformation(sourceInformation);
    } else {
      return new js.LiteralBool(value).withSourceInformation(sourceInformation);
    }
  }

  void generateConstant(
      ConstantValue constant, SourceInformation sourceInformation) {
    js.Expression expression = _emitter.constantReference(constant);
    if (!constant.isDummy) {
      // TODO(johnniwinther): Support source information on synthetic constants.
      expression = expression.withSourceInformation(sourceInformation);
    }
    push(expression);
  }

  @override
  visitConstant(HConstant node) {
    assert(isGenerateAtUseSite(node));
    generateConstant(node.constant, node.sourceInformation);

    _registry.registerConstantUse(new ConstantUse.literal(node.constant));
    if (node.constant.isType) {
      TypeConstantValue typeConstant = node.constant;
      _registry.registerTypeUse(
          new TypeUse.constTypeLiteral(typeConstant.representedType));
    }
  }

  @override
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
      if (left.isStringOrNull(_abstractValueDomain).isDefinitelyTrue &&
          right.isStringOrNull(_abstractValueDomain).isDefinitelyTrue) {
        return true;
      }

      // This optimization doesn't work for NaN, so we only do it if the
      // type is known to be an integer.
      return left.isInteger(_abstractValueDomain).isDefinitelyTrue &&
          right.isInteger(_abstractValueDomain).isDefinitelyTrue;
    }

    bool handledBySpecialCase = false;
    if (isGenerateAtUseSite(input)) {
      handledBySpecialCase = true;
      if (input is HIsTestSimple) {
        _emitIsTestSimple(input, negative: true);
      } else if (input is HNot) {
        use(input.inputs[0]);
      } else if (input is HIdentity) {
        emitIdentityComparison(input, sourceInformation, inverse: true);
      } else if (canGenerateOptimizedComparison(input)) {
        HRelational relational = input;
        constant_system.BinaryOperation operation = relational.operation();
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

  @override
  visitParameterValue(HParameterValue node) {
    assert(!isGenerateAtUseSite(node));
    String name = variableNames.getName(node);
    parameters.add(new js.Parameter(name));
    declaredLocals.add(name);
  }

  @override
  visitLocalValue(HLocalValue node) {
    assert(!isGenerateAtUseSite(node));
    String name = variableNames.getName(node);
    collectedVariableDeclarations.add(name);
  }

  @override
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

  @override
  visitReturn(HReturn node) {
    if (node.inputs.isEmpty) {
      pushStatement(js.Return().withSourceInformation(node.sourceInformation));
    } else {
      use(node.inputs.single);
      pushStatement(
          js.Return(pop()).withSourceInformation(node.sourceInformation));
    }
  }

  @override
  visitThis(HThis node) {
    push(new js.This());
  }

  @override
  visitThrow(HThrow node) {
    if (node.isRethrow) {
      use(node.inputs[0]);
      pushStatement(
          new js.Throw(pop()).withSourceInformation(node.sourceInformation));
    } else {
      generateThrowWithHelper(
          _commonElements.wrapExceptionHelper, node.inputs[0],
          sourceInformation: node.sourceInformation);
    }
  }

  @override
  visitAwait(HAwait node) {
    use(node.inputs[0]);
    push(new js.Await(pop()).withSourceInformation(node.sourceInformation));
  }

  @override
  visitYield(HYield node) {
    use(node.inputs[0]);
    pushStatement(new js.DartYield(pop(), node.hasStar)
        .withSourceInformation(node.sourceInformation));
  }

  @override
  visitRangeConversion(HRangeConversion node) {
    // Range conversion instructions are removed by the value range
    // analyzer.
    assert(false);
  }

  @override
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
        if (node.index.isInteger(_abstractValueDomain).isDefinitelyTrue) {
          under = js.js("# < 0", pop());
        } else {
          js.Expression jsIndex = pop();
          under = js.js("# >>> 0 !== #", [jsIndex, jsIndex]);
        }
      } else if (node.index
          .isInteger(_abstractValueDomain)
          .isPotentiallyFalse) {
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
      generateThrowWithHelper(_commonElements.throwIndexOutOfRangeException,
          [node.array, node.reportedIndex],
          sourceInformation: node.sourceInformation);
      currentContainer = oldContainer;
      thenBody = unwrapStatement(thenBody);
      pushStatement(new js.If.noElse(underOver, thenBody)
          .withSourceInformation(node.sourceInformation));
    } else {
      generateThrowWithHelper(_commonElements.throwIndexOutOfRangeException,
          [node.array, node.index]);
    }
  }

  void generateThrowWithHelper(FunctionEntity helper, argument,
      {SourceInformation sourceInformation}) {
    js.Expression jsHelper = _emitter.staticFunctionAccess(helper);
    List arguments = <js.Expression>[];
    if (argument is List) {
      argument.forEach((instruction) {
        use(instruction);
        arguments.add(pop());
      });
    } else {
      use(argument);
      arguments.add(pop());
    }
    _registry.registerStaticUse(new StaticUse.staticInvoke(
        helper, new CallStructure.unnamed(arguments.length)));
    js.Call value = new js.Call(jsHelper, arguments.toList(growable: false),
        sourceInformation: sourceInformation);
    // BUG(4906): Using throw/return here adds to the size of the generated code
    // but it has the advantage of explicitly telling the JS engine that
    // this code path will terminate abruptly. Needs more work.
    if (helper == _commonElements.wrapExceptionHelper) {
      pushStatement(
          new js.Throw(value).withSourceInformation(sourceInformation));
    } else {
      pushStatement(
          new js.Return(value).withSourceInformation(sourceInformation));
    }
  }

  @override
  visitThrowExpression(HThrowExpression node) {
    HInstruction argument = node.inputs[0];
    use(argument);

    FunctionEntity helper = _commonElements.throwExpressionHelper;
    _registry.registerStaticUse(
        new StaticUse.staticInvoke(helper, CallStructure.ONE_ARG));

    js.Expression jsHelper = _emitter.staticFunctionAccess(helper);
    js.Call value = new js.Call(jsHelper, [pop()])
        .withSourceInformation(node.sourceInformation);
    push(value);
  }

  @override
  void visitSwitch(HSwitch node) {
    // Switches are handled using [visitSwitchInfo].
  }

  @override
  void visitStatic(HStatic node) {
    MemberEntity element = node.element;
    assert(element.isFunction || element.isField);
    if (element.isFunction) {
      push(_emitter
          .staticClosureAccess(element)
          .withSourceInformation(node.sourceInformation));
      _registry.registerStaticUse(new StaticUse.staticTearOff(element));
    } else {
      push(_emitter
          .staticFieldAccess(element)
          .withSourceInformation(node.sourceInformation));
      _registry.registerStaticUse(new StaticUse.staticGet(element));
    }
  }

  @override
  void visitLazyStatic(HLazyStatic node) {
    FieldEntity element = node.element;
    _registry.registerStaticUse(new StaticUse.staticInit(element));
    js.Expression lazyGetter = _emitter.isolateLazyInitializerAccess(element);
    js.Call call = new js.Call(lazyGetter, <js.Expression>[],
        sourceInformation: node.sourceInformation);
    push(call);
  }

  @override
  void visitStaticStore(HStaticStore node) {
    _registry.registerStaticUse(new StaticUse.staticSet(node.element));
    js.Node variable = _emitter.staticFieldAccess(node.element);
    use(node.inputs[0]);
    push(new js.Assignment(variable, pop())
        .withSourceInformation(node.sourceInformation));
  }

  @override
  void visitStringConcat(HStringConcat node) {
    use(node.left);
    js.Expression jsLeft = pop();
    use(node.right);
    push(new js.Binary('+', jsLeft, pop())
        .withSourceInformation(node.sourceInformation));
  }

  @override
  void visitStringify(HStringify node) {
    HInstruction input = node.inputs.first;
    if (input.isString(_abstractValueDomain).isDefinitelyTrue) {
      use(input);
    } else if (input.isInteger(_abstractValueDomain).isDefinitelyTrue ||
        input.isBoolean(_abstractValueDomain).isDefinitelyTrue) {
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
      FunctionEntity convertToString =
          _commonElements.stringInterpolationHelper;
      _registry.registerStaticUse(
          new StaticUse.staticInvoke(convertToString, CallStructure.ONE_ARG));
      js.Expression jsHelper = _emitter.staticFunctionAccess(convertToString);
      use(input);
      push(new js.Call(jsHelper, <js.Expression>[pop()],
          sourceInformation: node.sourceInformation));
    }
  }

  @override
  void visitLiteralList(HLiteralList node) {
    _registry
        // ignore:deprecated_member_use_from_same_package
        .registerInstantiatedClass(_commonElements.listClass);
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

  @override
  void visitIndex(HIndex node) {
    use(node.receiver);
    js.Expression receiver = pop();
    use(node.index);
    push(new js.PropertyAccess(receiver, pop())
        .withSourceInformation(node.sourceInformation));
  }

  @override
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

  void checkTypeOf(HInstruction input, String cmp, String typeName,
      SourceInformation sourceInformation) {
    use(input);
    js.Expression typeOf = new js.Prefix("typeof", pop());
    push(new js.Binary(cmp, typeOf, js.string(typeName))
        .withSourceInformation(sourceInformation));
  }

  void checkNum(
      HInstruction input, String cmp, SourceInformation sourceInformation) {
    return checkTypeOf(input, cmp, 'number', sourceInformation);
  }

  void checkBool(
      HInstruction input, String cmp, SourceInformation sourceInformation) {
    return checkTypeOf(input, cmp, 'boolean', sourceInformation);
  }

  @override
  void visitPrimitiveCheck(HPrimitiveCheck node) {
    js.Expression test = _generateReceiverOrArgumentTypeTest(node);
    js.Block oldContainer = currentContainer;
    js.Statement body = new js.Block.empty();
    currentContainer = body;
    if (node.isArgumentTypeCheck) {
      generateThrowWithHelper(
          _commonElements.throwIllegalArgumentException, node.checkedInput,
          sourceInformation: node.sourceInformation);
    } else if (node.isReceiverTypeCheck) {
      use(node.checkedInput);
      js.Name methodName =
          _namer.invocationName(node.receiverTypeCheckSelector);
      js.Expression call = js.propertyCall(
          pop(), methodName, []).withSourceInformation(node.sourceInformation);
      pushStatement(
          new js.Return(call).withSourceInformation(node.sourceInformation));
    }
    currentContainer = oldContainer;
    body = unwrapStatement(body);
    pushStatement(new js.If.noElse(test, body)
        .withSourceInformation(node.sourceInformation));
  }

  js.Expression _generateReceiverOrArgumentTypeTest(HPrimitiveCheck node) {
    DartType type = node.typeExpression;
    HInstruction input = node.checkedInput;
    AbstractValue checkedType = node.checkedType;
    // This path is no longer used for indexable primitive types.
    assert(_abstractValueDomain.isJsIndexable(checkedType).isPotentiallyFalse);
    // Figure out if it is beneficial to use a null check.  V8 generally prefers
    // 'typeof' checks, but for integers we cannot compile this test into a
    // single typeof check so the null check is cheaper.
    if (type == _commonElements.numType) {
      // input is !num
      checkNum(input, '!==', input.sourceInformation);
      return pop();
    }
    if (type == _commonElements.boolType) {
      // input is !bool
      checkBool(input, '!==', input.sourceInformation);
      return pop();
    }
    throw failedAt(input, 'Unexpected check: $type.');
  }

  @override
  void visitBoolConversion(HBoolConversion node) {
    _registry.registerTypeUse(new TypeUse.isCheck(_commonElements.boolType));
    CheckedModeHelper helper = const CheckedModeHelper('boolConversionCheck');
    StaticUse staticUse = helper.getStaticUse(_commonElements);
    _registry.registerStaticUse(staticUse);
    use(node.checkedInput);
    List<js.Expression> arguments = [pop()];
    push(
        new js.Call(_emitter.staticFunctionAccess(staticUse.element), arguments)
            .withSourceInformation(node.sourceInformation));
  }

  @override
  void visitNullCheck(HNullCheck node) {
    use(node.checkedInput);
    // We access a JavaScript member 'toString' as all objects besides `null`
    // and `undefined` have it.

    // TODO(35996): Pick a shorter field. The instruction has a selector and
    // field that could be used here to pick the 'right' field. The 'field'
    // might need to be propagated to an earlier HNullCheck. JSArray and
    // JSString have 'length'.
    pushStatement(js.ExpressionStatement(
        js.PropertyAccess.field(pop(), 'toString')
            .withSourceInformation(node.sourceInformation)));
  }

  @override
  void visitTypeKnown(HTypeKnown node) {
    // [HTypeKnown] instructions are removed before generating code.
    assert(false);
  }

  @override
  void visitRef(HRef node) {
    visit(node.value);
  }

  @override
  visitIsTest(HIsTest node) {
    _registry.registerTypeUse(new TypeUse.isCheck(node.dartType));

    use(node.typeInput);
    js.Expression first = pop();
    use(node.checkedInput);
    js.Expression second = pop();

    FieldEntity field = _commonElements.rtiIsField;
    js.Name name = _namer.instanceFieldPropertyName(field);

    push(js.js('#.#(#)', [first, name, second]).withSourceInformation(
        node.sourceInformation));
  }

  @override
  visitIsTestSimple(HIsTestSimple node) {
    _emitIsTestSimple(node);
  }

  _emitIsTestSimple(HIsTestSimple node, {bool negative: false}) {
    use(node.checkedInput);
    js.Expression value = pop();
    String relation = negative ? '!=' : '==';

    js.Expression handleNegative(js.Expression test) =>
        negative ? js.Prefix('!', test) : test;

    js.Expression typeof(String type) =>
        js.Binary(relation, js.Prefix('typeof', value), js.string(type));

    js.Expression isTest(MemberEntity helper) {
      _registry.registerStaticUse(
          StaticUse.staticInvoke(helper, CallStructure.ONE_ARG));
      js.Expression test =
          js.Call(_emitter.staticFunctionAccess(helper), [value]);
      return handleNegative(test);
    }

    js.Expression test;
    switch (node.specialization) {
      case IsTestSpecialization.isNull:
      case IsTestSpecialization.notNull:
        // These cases should be lowered using [HIdentity] during optimization.
        failedAt(node, 'Missing lowering');
        break;

      case IsTestSpecialization.string:
        test = typeof("string");
        break;

      case IsTestSpecialization.bool:
        test = isTest(_commonElements.specializedIsBool);
        break;

      case IsTestSpecialization.num:
        test = typeof("number");
        break;

      case IsTestSpecialization.int:
        test = isTest(_commonElements.specializedIsInt);
        break;

      case IsTestSpecialization.arrayTop:
        test = handleNegative(js.js('Array.isArray(#)', [value]));
        break;

      case IsTestSpecialization.instanceof:
        DartType dartType = node.dartType;
        // We don't generate instancof specializations for Never* and Object*.
        assert(dartType is InterfaceType ||
            (dartType is LegacyType &&
                !dartType.baseType.isObject &&
                dartType.baseType is! NeverType));
        InterfaceType type = dartType.withoutNullability;
        _registry.registerTypeUse(TypeUse.constructorReference(type));
        test = handleNegative(js.js('# instanceof #',
            [value, _emitter.constructorAccess(type.element)]));
    }
    push(test.withSourceInformation(node.sourceInformation));
  }

  @override
  visitAsCheck(HAsCheck node) {
    use(node.typeInput);
    js.Expression first = pop();
    use(node.checkedInput);
    js.Expression second = pop();

    _registry.registerTypeUse(TypeUse.isCheck(node.checkedTypeExpression));

    FieldEntity field = _commonElements.rtiAsField;
    js.Name name = _namer.instanceFieldPropertyName(field);

    push(js.js('#.#(#)', [first, name, second]).withSourceInformation(
        node.sourceInformation));
  }

  @override
  visitAsCheckSimple(HAsCheckSimple node) {
    use(node.checkedInput);
    MemberEntity method = node.method;
    _registry.registerStaticUse(
        StaticUse.staticInvoke(method, CallStructure.ONE_ARG));
    js.Expression methodAccess = _emitter.staticFunctionAccess(method);
    push(js.js(r'#(#)', [methodAccess, pop()]).withSourceInformation(
        node.sourceInformation));
  }

  @override
  visitSubtypeCheck(HSubtypeCheck node) {
    throw UnimplementedError('SsaCodeGenerator.visitSubtypeCheck  $node');
  }

  @override
  visitLoadType(HLoadType node) {
    // 'findType' will be called somewhere to initialize the type reference.
    _registry.registerStaticUse(StaticUse.staticInvoke(
        _commonElements.findType, CallStructure.ONE_ARG));
    TypeReference reference = TypeReference(node.typeExpression);
    reference.forLazyInitializer = currentGraph.isLazyInitializer;
    push(reference);
  }

  @override
  visitInstanceEnvironment(HInstanceEnvironment node) {
    HInstruction input = node.inputs.single;
    use(input);
    js.Expression receiver = pop();

    void useRtiField() {
      push(js.js(r'#.#', [receiver, _namer.rtiFieldJsName]));
    }

    void useHelper(FunctionEntity helper) {
      _registry.registerStaticUse(
          new StaticUse.staticInvoke(helper, CallStructure.ONE_ARG));
      js.Expression helperAccess = _emitter.staticFunctionAccess(helper);
      push(js.js(r'#(#)', [helperAccess, receiver]).withSourceInformation(
          node.sourceInformation));
    }

    // Try to use the 'rti' field, or a specialization of 'instanceType'.
    AbstractValue receiverMask = node.codegenInputType;

    AbstractBool isArray = _abstractValueDomain.isInstanceOf(
        receiverMask, _commonElements.jsArrayClass);

    if (isArray.isDefinitelyTrue) {
      useHelper(_commonElements.arrayInstanceType);
      return;
    }

    if (isArray.isDefinitelyFalse) {
      // See if the receiver type narrows the set of classes to ones that all
      // have a stored type field.
      // TODO(sra): Currently the only convenient query is [getExactClass]. We
      // should have a (cached) query to iterate over all the concrete classes
      // in [receiverMask].
      // TODO(sra): Store the context class on the HInstanceEnvironment. This
      // would allow the subtype classes to be iterated.
      ClassEntity receiverClass =
          _abstractValueDomain.getExactClass(receiverMask);
      if (receiverClass != null) {
        if (_closedWorld.rtiNeed.classNeedsTypeArguments(receiverClass)) {
          useRtiField();
          return;
        }
      }

      // If the type is not intercepted and is not a closure, use the 'simple'
      // helper.
      if (_abstractValueDomain.isInterceptor(receiverMask).isDefinitelyFalse) {
        if (_abstractValueDomain
            .isInstanceOf(receiverMask, _commonElements.closureClass)
            .isDefinitelyFalse) {
          useHelper(_commonElements.simpleInstanceType);
          return;
        }
      }
    }

    useHelper(_commonElements.instanceType);
  }

  @override
  visitTypeEval(HTypeEval node) {
    // Call `env._eval("recipe")`.
    use(node.inputs[0]);
    js.Expression environment = pop();

    // Instead of generating `env._eval("$n")`, generate appropriate field
    // accesses where possible.
    TypeEnvironmentStructure envStructure = node.envStructure;
    TypeRecipe typeExpression = node.typeExpression;
    if (envStructure is FullTypeEnvironmentStructure &&
        typeExpression is TypeExpressionRecipe) {
      if (typeExpression.type is TypeVariableType) {
        TypeVariableType type = typeExpression.type;
        int index = indexTypeVariable(
            _closedWorld, _rtiSubstitutions, envStructure, type);
        if (index != null) {
          assert(index >= 1);
          List<TypeVariableType> bindings = envStructure.bindings;
          if (bindings.isNotEmpty) {
            // If the environment is a binding RTI, we should never index past
            // its length (i.e. into its base), since in that case, we could
            // eval against the base directly.
            assert(index <= bindings.length);
          } else {
            // If the environment is an interface RTI, use precomputed fields
            // for common accesses.
            if (index == 1) {
              push(_loadField(environment, _commonElements.rtiPrecomputed1Field,
                  node.sourceInformation));
              return;
            }
          }

          js.Expression rest = _loadField(environment,
              _commonElements.rtiRestField, node.sourceInformation);
          push(js.PropertyAccess.indexed(rest, index - 1)
              .withSourceInformation(node.sourceInformation));
          return;
        }
      }
    }

    RecipeEncoding encoding = _rtiRecipeEncoder.encodeRecipe(
        _emitter, node.envStructure, node.typeExpression);
    js.Expression recipe = encoding.recipe;

    for (TypeVariableType typeVariable in encoding.typeVariables) {
      _registry.registerTypeUse(TypeUse.namedTypeVariableNewRti(typeVariable));
    }

    MemberEntity method = _commonElements.rtiEvalMethod;
    Selector selector = Selector.fromElement(method);
    js.Name methodLiteral = _namer.invocationName(selector);
    push(js.js('#.#(#)', [
      environment,
      methodLiteral,
      recipe
    ]).withSourceInformation(node.sourceInformation));

    _registry.registerStaticUse(
        new StaticUse.directInvoke(method, selector.callStructure, null));
  }

  @override
  visitTypeBind(HTypeBind node) {
    // Call `env1._bind(env2)`.
    assert(node.inputs.length == 2);
    use(node.inputs[0]);
    js.Expression environment = pop();
    use(node.inputs[1]);
    js.Expression extensions = pop();

    MemberEntity method = _commonElements.rtiBindMethod;
    Selector selector = Selector.fromElement(method);
    js.Name methodLiteral = _namer.invocationName(selector);
    push(js.js('#.#(#)', [
      environment,
      methodLiteral,
      extensions
    ]).withSourceInformation(node.sourceInformation));

    _registry.registerStaticUse(
        new StaticUse.directInvoke(method, selector.callStructure, null));
  }
}
