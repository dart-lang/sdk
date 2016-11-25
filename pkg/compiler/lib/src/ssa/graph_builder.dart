// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../closure.dart';
import '../common.dart';
import '../common/codegen.dart' show CodegenRegistry;
import '../compiler.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../js_backend/js_backend.dart';
import '../resolution/tree_elements.dart';
import '../tree/tree.dart' as ast;
import '../types/types.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/use.dart' show TypeUse;
import '../world.dart' show ClosedWorld;
import 'jump_handler.dart';
import 'locals_handler.dart';
import 'nodes.dart';
import 'ssa_branch_builder.dart';
import 'type_builder.dart';

/// Base class for objects that build up an SSA graph.
///
/// This contains helpers for building the graph and tracking information about
/// the current state of the graph being built.
abstract class GraphBuilder {
  /// Holds the resulting SSA graph.
  final HGraph graph = new HGraph();

  // TODO(het): remove this
  /// A reference to the compiler.
  Compiler compiler;

  /// The JavaScript backend we are targeting in this compilation.
  JavaScriptBackend get backend;

  /// The tree elements for the element being built into an SSA graph.
  TreeElements get elements;

  CodegenRegistry get registry;

  /// Used to track the locals while building the graph.
  LocalsHandler localsHandler;

  /// A stack of instructions.
  ///
  /// We build the SSA graph by simulating a stack machine.
  List<HInstruction> stack = <HInstruction>[];

  /// The count of nested loops we are currently building.
  ///
  /// The loop nesting is consulted when inlining a function invocation. The
  /// inlining heuristics take this information into account.
  int loopDepth = 0;

  /// A mapping from jump targets to their handlers.
  Map<JumpTarget, JumpHandler> jumpTargets = <JumpTarget, JumpHandler>{};

  void push(HInstruction instruction) {
    add(instruction);
    stack.add(instruction);
  }

  HInstruction pop() {
    return stack.removeLast();
  }

  /// Pops the most recent instruction from the stack and 'boolifies' it.
  ///
  /// Boolification is checking if the value is '=== true'.
  HInstruction popBoolified();

  /// Pushes a boolean checking [expression] against null.
  pushCheckNull(HInstruction expression) {
    push(new HIdentity(
        expression, graph.addConstantNull(compiler), null, backend.boolType));
  }

  void dup() {
    stack.add(stack.last);
  }

  HBasicBlock _current;

  /// The current block to add instructions to. Might be null, if we are
  /// visiting dead code, but see [isReachable].
  HBasicBlock get current => _current;

  void set current(c) {
    isReachable = c != null;
    _current = c;
  }

  /// The most recently opened block. Has the same value as [current] while
  /// the block is open, but unlike [current], it isn't cleared when the
  /// current block is closed.
  HBasicBlock lastOpenedBlock;

  /// Indicates whether the current block is dead (because it has a throw or a
  /// return further up). If this is false, then [current] may be null. If the
  /// block is dead then it may also be aborted, but for simplicity we only
  /// abort on statement boundaries, not in the middle of expressions. See
  /// [isAborted].
  bool isReachable = true;

  HParameterValue lastAddedParameter;

  Map<ParameterElement, HInstruction> parameters =
      <ParameterElement, HInstruction>{};

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

  /// Creates a new block, transitions to it from any current block, and
  /// opens the new block.
  HBasicBlock openNewBlock() {
    HBasicBlock newBlock = addNewBlock();
    if (!isAborted()) goto(current, newBlock);
    open(newBlock);
    return newBlock;
  }

  void add(HInstruction instruction) {
    current.add(instruction);
  }

  HParameterValue addParameter(Entity parameter, TypeMask type) {
    HParameterValue result = new HParameterValue(parameter, type);
    if (lastAddedParameter == null) {
      graph.entry.addBefore(graph.entry.first, result);
    } else {
      graph.entry.addAfter(lastAddedParameter, result);
    }
    lastAddedParameter = result;
    return result;
  }

  void handleIf(
      {ast.Node node,
      void visitCondition(),
      void visitThen(),
      void visitElse(),
      SourceInformation sourceInformation}) {
    SsaBranchBuilder branchBuilder = new SsaBranchBuilder(this, compiler, node);
    branchBuilder.handleIf(visitCondition, visitThen, visitElse,
        sourceInformation: sourceInformation);
  }

  HSubGraphBlockInformation wrapStatementGraph(SubGraph statements) {
    if (statements == null) return null;
    return new HSubGraphBlockInformation(statements);
  }

  HSubExpressionBlockInformation wrapExpressionGraph(SubExpression expression) {
    if (expression == null) return null;
    return new HSubExpressionBlockInformation(expression);
  }

  HInstruction buildFunctionType(FunctionType type) {
    type.accept(
        new ReifiedTypeRepresentationBuilder(compiler.closedWorld), this);
    return pop();
  }

  HInstruction buildFunctionTypeConversion(
      HInstruction original, DartType type, int kind);

  /// Returns the current source element.
  ///
  /// The returned element is a declaration element.
  Element get sourceElement;

  // TODO(karlklose): this is needed to avoid a bug where the resolved type is
  // not stored on a type annotation in the closure translator. Remove when
  // fixed.
  bool hasDirectLocal(Local local) {
    return !localsHandler.isAccessedDirectly(local) ||
        localsHandler.directLocals[local] != null;
  }

  HInstruction callSetRuntimeTypeInfoWithTypeArguments(
      DartType type, List<HInstruction> rtiInputs, HInstruction newObject) {
    if (!backend.classNeedsRti(type.element)) {
      return newObject;
    }

    HInstruction typeInfo = new HTypeInfoExpression(
        TypeInfoExpressionKind.INSTANCE,
        (type.element as ClassElement).thisType,
        rtiInputs,
        backend.dynamicType);
    add(typeInfo);
    return callSetRuntimeTypeInfo(typeInfo, newObject);
  }

  HInstruction callSetRuntimeTypeInfo(
      HInstruction typeInfo, HInstruction newObject);

  /// The element for which this SSA builder is being used.
  Element get targetElement;
  TypeBuilder get typeBuilder;
}

class ReifiedTypeRepresentationBuilder
    implements DartTypeVisitor<dynamic, GraphBuilder> {
  final ClosedWorld closedWorld;

  ReifiedTypeRepresentationBuilder(this.closedWorld);

  void visit(DartType type, GraphBuilder builder) => type.accept(this, builder);

  void visitVoidType(VoidType type, GraphBuilder builder) {
    ClassElement cls = builder.backend.helpers.VoidRuntimeType;
    builder.push(new HVoidType(type, new TypeMask.exact(cls, closedWorld)));
  }

  void visitTypeVariableType(TypeVariableType type, GraphBuilder builder) {
    ClassElement cls = builder.backend.helpers.RuntimeType;
    TypeMask instructionType = new TypeMask.subclass(cls, closedWorld);
    if (!builder.sourceElement.enclosingElement.isClosure &&
        builder.sourceElement.isInstanceMember) {
      HInstruction receiver = builder.localsHandler.readThis();
      builder.push(new HReadTypeVariable(type, receiver, instructionType));
    } else {
      builder.push(new HReadTypeVariable.noReceiver(
          type,
          builder.typeBuilder
              .addTypeVariableReference(type, builder.sourceElement),
          instructionType));
    }
  }

  void visitFunctionType(FunctionType type, GraphBuilder builder) {
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

    List<DartType> namedParameterTypes = type.namedParameterTypes;
    List<String> names = type.namedParameters;
    for (int index = 0; index < names.length; index++) {
      ast.DartString dartString = new ast.DartString.literal(names[index]);
      inputs.add(builder.graph.addConstantString(dartString, builder.compiler));
      namedParameterTypes[index].accept(this, builder);
      inputs.add(builder.pop());
    }

    ClassElement cls = builder.backend.helpers.RuntimeFunctionType;
    builder.push(
        new HFunctionType(inputs, type, new TypeMask.exact(cls, closedWorld)));
  }

  void visitMalformedType(MalformedType type, GraphBuilder builder) {
    visitDynamicType(const DynamicType(), builder);
  }

  void visitStatementType(StatementType type, GraphBuilder builder) {
    throw 'not implemented visitStatementType($type)';
  }

  void visitInterfaceType(InterfaceType type, GraphBuilder builder) {
    List<HInstruction> inputs = <HInstruction>[];
    for (DartType typeArgument in type.typeArguments) {
      typeArgument.accept(this, builder);
      inputs.add(builder.pop());
    }
    ClassElement cls;
    if (type.typeArguments.isEmpty) {
      cls = builder.backend.helpers.RuntimeTypePlain;
    } else {
      cls = builder.backend.helpers.RuntimeTypeGeneric;
    }
    builder.push(
        new HInterfaceType(inputs, type, new TypeMask.exact(cls, closedWorld)));
  }

  void visitTypedefType(TypedefType type, GraphBuilder builder) {
    DartType unaliased = type.unaliased;
    if (unaliased is TypedefType) throw 'unable to unalias $type';
    unaliased.accept(this, builder);
  }

  void visitDynamicType(DynamicType type, GraphBuilder builder) {
    JavaScriptBackend backend = builder.compiler.backend;
    ClassElement cls = backend.helpers.DynamicRuntimeType;
    builder.push(new HDynamicType(type, new TypeMask.exact(cls, closedWorld)));
  }
}
