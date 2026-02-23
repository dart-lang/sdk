// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/field.dart';
import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/local_variable.dart';
import 'package:cfg/ir/source_position.dart';
import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart'
    as ast
    show DartType, Name, VariableDeclaration;

/// Helper class to create IR instructions and populate [FlowGraph].
///
/// Maintains current basic block and appends newly created
/// instructions to the end of the current block.
///
/// Simulates expression stack. When creating IR instructions,
/// their inputs are populated from the expression stack.
///
/// Keeps current source position which is used for all
/// created IR instructions.
///
/// Maintains a stack of entered try-blocks (exception handlers).
/// All newly created basic blocks get a top exception handler.
///
/// All other attributes and optional inputs are passed explicitly
/// when creating IR instructions.
class FlowGraphBuilder {
  /// Current graph being constructed.
  final FlowGraph graph;

  /// Source position for the new instructions.
  SourcePosition currentSourcePosition = noPosition;

  /// Simulated expression stack.
  final List<Definition> stack = [];

  /// Last instruction in the current block.
  Instruction? _last;

  /// Stack of the exception handlers.
  List<CatchBlock> _exceptionHandlers = [];

  FlowGraphBuilder(CFunction function) : graph = FlowGraph(function) {
    _last = graph.entryBlock;
  }

  /// Finish building CFG.
  FlowGraph done() {
    assert(!hasOpenBlock);
    graph.discoverBlocks();
    return graph;
  }

  /// Start filling [block] with instructions.
  void startBlock(Block block) {
    _last = block;
    if (_exceptionHandlers.isNotEmpty) {
      block.exceptionHandler = _exceptionHandlers.last;
    }
  }

  /// Append [instr] to the current block.
  void appendInstruction(Instruction instr) {
    _last!.appendInstruction(instr);
    _last = instr;
  }

  /// End the current block.
  void endBlock() {
    _last = null;
  }

  /// Returns `true` if there is an unfinished basic block being built.
  bool get hasOpenBlock => _last != null;

  /// Push result of [def] into the expression stack.
  void push(Definition def) {
    stack.add(def);
  }

  /// Pop and return value from the top of the expression stack.
  Definition pop() => stack.removeLast();

  /// Returns value from the top of the expression stack without removing it.
  Definition get stackTop => stack.last;

  /// Pop [count] values from the expression stack and
  /// use them as `first ... first + count - 1` inputs of [instr]
  /// (in the reverse order).
  void popInputs(Instruction instr, int first, int count) {
    for (int i = count - 1; i >= 0; --i) {
      instr.setInputAt(first + i, pop());
    }
  }

  /// Pop [count] values from the expression stack.
  void drop(int count) {
    stack.removeRange(stack.length - count, stack.length);
  }

  /// Create a new [JoinBlock].
  JoinBlock newJoinBlock() => JoinBlock(graph, currentSourcePosition);

  /// Create a new [TargetBlock].
  TargetBlock newTargetBlock() => TargetBlock(graph, currentSourcePosition);

  /// Create a new [CatchBlock].
  CatchBlock newCatchBlock() => CatchBlock(graph, currentSourcePosition);

  /// Append [Goto] to the graph. Ends current block.
  void addGoto(Block target) {
    final instr = Goto(graph, currentSourcePosition);
    appendInstruction(instr);
    final currentBlock = instr.block!;
    assert(currentBlock.successors.isEmpty);
    currentBlock.successors.add(target);
    endBlock();
  }

  /// Append [Branch] to the graph. Ends current block.
  void addBranch(TargetBlock trueSuccessor, TargetBlock falseSuccessor) {
    final instr = Branch(graph, currentSourcePosition, pop());
    appendInstruction(instr);
    final currentBlock = instr.block!;
    assert(currentBlock.successors.isEmpty);
    currentBlock.successors.add(trueSuccessor);
    currentBlock.successors.add(falseSuccessor);
    endBlock();
  }

  /// Append [TryEntry] to the graph. Ends current block.
  void addTryEntry(TargetBlock tryBody, CatchBlock catchBlock) {
    final instr = TryEntry(graph, currentSourcePosition);
    appendInstruction(instr);
    final currentBlock = instr.block!;
    assert(currentBlock.successors.isEmpty);
    currentBlock.successors.add(tryBody);
    currentBlock.successors.add(catchBlock);
    endBlock();
  }

  /// Enter try-block with given [exceptionHandler].
  void enterTryBlock(CatchBlock exceptionHandler) {
    _exceptionHandlers.add(exceptionHandler);
  }

  /// Leave the last entered try-block.
  void leaveTryBlock() {
    _exceptionHandlers.removeLast();
  }

  /// Append [Return] to the graph. Ends current block.
  void addReturn() {
    final value = pop();
    final instr = Return(graph, currentSourcePosition, value);
    appendInstruction(instr);
    endBlock();
  }

  /// Append [Comparison] to the graph.
  Comparison addComparison(ComparisonOpcode op) {
    final right = pop();
    final left = pop();
    final instr = Comparison(graph, currentSourcePosition, op, left, right);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [Constant] to the entry block of the graph.
  Constant addConstant(ConstantValue value) {
    final instr = graph.getConstant(value);
    if (instr.previous == _last) {
      _last = instr;
    }
    push(instr);
    return instr;
  }

  /// Append `null` [Constant].
  Constant addNullConstant() => addConstant(ConstantValue.fromNull());

  /// Append `int` [Constant] with given [value].
  Constant addIntConstant(int value) =>
      addConstant(ConstantValue.fromInt(value));

  /// Append `bool` [Constant] with given [value].
  Constant addBoolConstant(bool value) =>
      addConstant(ConstantValue.fromBool(value));

  /// Append [DirectCall] to the graph.
  DirectCall addDirectCall(
    CFunction target,
    int inputCount,
    ArgumentsShape argumentsShape,
    CType type,
  ) {
    final instr = DirectCall(
      graph,
      currentSourcePosition,
      target,
      type,
      inputCount: inputCount,
      argumentsShape: argumentsShape,
    );
    popInputs(instr, 0, inputCount);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [InterfaceCall] to the graph.
  InterfaceCall addInterfaceCall(
    CFunction interfaceTarget,
    int inputCount,
    ArgumentsShape argumentsShape,
    CType type,
  ) {
    final instr = InterfaceCall(
      graph,
      currentSourcePosition,
      interfaceTarget,
      type,
      inputCount: inputCount,
      argumentsShape: argumentsShape,
    );
    popInputs(instr, 0, inputCount);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [ClosureCall] to the graph.
  ClosureCall addClosureCall(
    int inputCount,
    ArgumentsShape argumentsShape,
    CType type,
  ) {
    final instr = ClosureCall(
      graph,
      currentSourcePosition,
      type,
      inputCount: inputCount,
      argumentsShape: argumentsShape,
    );
    popInputs(instr, 0, inputCount);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [DynamicCall] to the graph.
  DynamicCall addDynamicCall(
    ast.Name selector,
    DynamicCallKind kind,
    int inputCount,
    ArgumentsShape argumentsShape,
  ) {
    final instr = DynamicCall(
      graph,
      currentSourcePosition,
      selector,
      kind,
      inputCount: inputCount,
      argumentsShape: argumentsShape,
    );
    popInputs(instr, 0, inputCount);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Add [LocalVariable] to the graph.
  LocalVariable declareLocalVariable(
    String name,
    ast.VariableDeclaration? declaration,
    CType type,
  ) {
    final v = LocalVariable(
      name,
      declaration,
      graph.localVariables.length,
      type,
    );
    graph.localVariables.add(v);
    return v;
  }

  /// Append [Parameter] instruction to the graph.
  Parameter addParameter(LocalVariable variable) {
    final instr = Parameter(graph, currentSourcePosition, variable);
    appendInstruction(instr);
    return instr;
  }

  /// Append [LoadLocal] to the graph.
  LoadLocal addLoadLocal(LocalVariable variable) {
    final instr = LoadLocal(graph, currentSourcePosition, variable);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [StoreLocal] to the graph.
  ///
  /// If [leaveValueOnStack] is `true`, then the stored value is left
  /// on top of the expression stack.
  void addStoreLocal(LocalVariable variable, {bool leaveValueOnStack = false}) {
    final value = pop();
    final instr = StoreLocal(graph, currentSourcePosition, variable, value);
    if (leaveValueOnStack) {
      push(value);
    }
    appendInstruction(instr);
  }

  /// Append [LoadInstanceField] to the graph.
  LoadInstanceField addLoadInstanceField(
    CField field, {
    bool checkInitialized = false,
  }) {
    final object = pop();
    final instr = LoadInstanceField(
      graph,
      currentSourcePosition,
      field,
      object,
      checkInitialized: checkInitialized,
    );
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [StoreInstanceField] to the graph.
  StoreInstanceField addStoreInstanceField(
    CField field, {
    bool checkNotInitialized = false,
  }) {
    final value = pop();
    final object = pop();
    final instr = StoreInstanceField(
      graph,
      currentSourcePosition,
      field,
      object,
      value,
      checkNotInitialized: checkNotInitialized,
    );
    appendInstruction(instr);
    return instr;
  }

  /// Append [LoadStaticField] to the graph.
  LoadStaticField addLoadStaticField(
    CField field, {
    bool checkInitialized = false,
  }) {
    final instr = LoadStaticField(
      graph,
      currentSourcePosition,
      field,
      checkInitialized: checkInitialized,
    );
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [StoreStaticField] to the graph.
  StoreStaticField addStoreStaticField(
    CField field, {
    bool checkNotInitialized = false,
  }) {
    final value = pop();
    final instr = StoreStaticField(
      graph,
      currentSourcePosition,
      field,
      value,
      checkNotInitialized: checkNotInitialized,
    );
    appendInstruction(instr);
    return instr;
  }

  /// Append [Throw] taking an exception as input to the graph.
  /// Ends current block.
  void addThrow() {
    final exception = pop();
    final instr = Throw(graph, currentSourcePosition, exception, null);
    appendInstruction(instr);
    endBlock();
  }

  /// Append [Throw] taking an exception and stack trace as inputs to
  /// the graph. Ends current block.
  void addRethrow() {
    final stackTrace = pop();
    final exception = pop();
    final instr = Throw(graph, currentSourcePosition, exception, stackTrace);
    appendInstruction(instr);
    endBlock();
  }

  /// Append [NullCheck] to the graph.
  NullCheck addNullCheck() {
    final object = pop();
    final instr = NullCheck(graph, currentSourcePosition, object);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [TypeParameters] to the graph.
  ///
  /// Optional [receiver] input should be passed if there are class type
  /// parameters in scope.
  TypeParameters addTypeParameters({Definition? receiver}) {
    final instr = TypeParameters(graph, currentSourcePosition, receiver);
    appendInstruction(instr);
    return instr;
  }

  /// Append [TypeCast] to the graph.
  ///
  /// Optional [typeParameters] input should be passed if tested type
  /// depends on type parameters (not fully instantiated).
  ///
  /// Optional [isChecked] argument indicates if this type cast involves
  /// check at runtime.
  TypeCast addTypeCast(
    CType testedType, {
    Definition? typeParameters,
    bool isChecked = true,
  }) {
    final object = pop();
    final instr = TypeCast(
      graph,
      currentSourcePosition,
      object,
      testedType,
      typeParameters,
      isChecked: isChecked,
    );
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [TypeTest] to the graph.
  ///
  /// Optional [typeParameters] input should be passed if tested type
  /// depends on type parameters (not fully instantiated).
  TypeTest addTypeTest(CType testedType, {Definition? typeParameters}) {
    final object = pop();
    final instr = TypeTest(
      graph,
      currentSourcePosition,
      object,
      testedType,
      typeParameters,
    );
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append either [TypeArguments] or [Constant] representing type arguments
  /// to the graph.
  ///
  /// Optional [typeParameters] input should be passed if type arguments
  /// depend on type parameters (not fully instantiated).
  void addTypeArguments(
    List<ast.DartType> types, {
    Definition? typeParameters,
  }) {
    if (typeParameters == null) {
      addConstant(ConstantValue(TypeArgumentsConstant(types)));
      return;
    }
    final instr = TypeArguments(
      graph,
      currentSourcePosition,
      types,
      typeParameters,
    );
    push(instr);
    appendInstruction(instr);
  }

  /// Append [TypeLiteral] to the graph.
  TypeLiteral addTypeLiteral(
    ast.DartType uninstantiatedType, {
    required Definition typeParameters,
  }) {
    final instr = TypeLiteral(
      graph,
      currentSourcePosition,
      uninstantiatedType,
      typeParameters,
    );
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [AllocateObject] to the graph.
  ///
  /// Optional [typeArguments] input should be passed if allocating
  /// an instance of a generic class.
  AllocateObject addAllocateObject(CType type, {Definition? typeArguments}) {
    final instr = AllocateObject(
      graph,
      currentSourcePosition,
      type,
      typeArguments,
    );
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [AllocateClosure] to the graph.
  AllocateClosure addAllocateClosure(
    ClosureFunction function,
    CType type,
    int inputCount,
  ) {
    final instr = AllocateClosure(
      graph,
      currentSourcePosition,
      function,
      type,
      inputCount: inputCount,
    );
    popInputs(instr, 0, inputCount);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [AllocateListLiteral] to the graph.
  /// Takes type arguments and elements from the stack as inputs.
  AllocateListLiteral addAllocateListLiteral(CType type, int inputCount) {
    final instr = AllocateListLiteral(
      graph,
      currentSourcePosition,
      type,
      inputCount: inputCount,
    );
    popInputs(instr, 0, inputCount);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [AllocateMapLiteral] to the graph.
  /// Takes type arguments and key/value pairs from the stack as inputs.
  AllocateMapLiteral addAllocateMapLiteral(CType type, int inputCount) {
    final instr = AllocateMapLiteral(
      graph,
      currentSourcePosition,
      type,
      inputCount: inputCount,
    );
    popInputs(instr, 0, inputCount);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [StringInterpolation] to the graph.
  StringInterpolation addStringInterpolation(int inputCount) {
    final instr = StringInterpolation(
      graph,
      currentSourcePosition,
      inputCount: inputCount,
    );
    popInputs(instr, 0, inputCount);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [BinaryIntOp] to the graph.
  BinaryIntOp addBinaryIntOp(BinaryIntOpcode op) {
    final right = pop();
    final left = pop();
    final instr = BinaryIntOp(graph, currentSourcePosition, op, left, right);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [UnaryIntOp] to the graph.
  UnaryIntOp addUnaryIntOp(UnaryIntOpcode op) {
    final operand = pop();
    final instr = UnaryIntOp(graph, currentSourcePosition, op, operand);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [BinaryDoubleOp] to the graph.
  BinaryDoubleOp addBinaryDoubleOp(BinaryDoubleOpcode op) {
    final right = pop();
    final left = pop();
    final instr = BinaryDoubleOp(graph, currentSourcePosition, op, left, right);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [UnaryDoubleOp] to the graph.
  UnaryDoubleOp addUnaryDoubleOp(UnaryDoubleOpcode op) {
    final operand = pop();
    final instr = UnaryDoubleOp(graph, currentSourcePosition, op, operand);
    push(instr);
    appendInstruction(instr);
    return instr;
  }

  /// Append [UnaryBoolOp] to the graph.
  UnaryBoolOp addUnaryBoolOp(UnaryBoolOpcode op) {
    final operand = pop();
    final instr = UnaryBoolOp(graph, currentSourcePosition, op, operand);
    push(instr);
    appendInstruction(instr);
    return instr;
  }
}
