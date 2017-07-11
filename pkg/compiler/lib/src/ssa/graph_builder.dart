// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../closure.dart' show ClosureDataLookup;
import '../constants/constant_system.dart';
import '../common/codegen.dart' show CodegenRegistry;
import '../common_elements.dart';
import '../compiler.dart';
import '../deferred_load.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../elements/elements.dart';
import '../elements/entities.dart' show Entity, Local, MemberEntity;
import '../elements/jumps.dart';
import '../elements/types.dart';
import '../js_backend/backend.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/constant_handler_javascript.dart';
import '../js_backend/namer.dart';
import '../js_backend/native_data.dart';
import '../js_backend/js_interop_analysis.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/mirrors_data.dart';
import '../js_backend/runtime_types.dart';
import '../js_emitter/code_emitter_task.dart';
import '../options.dart';
import '../resolution/tree_elements.dart';
import '../types/types.dart';
import '../world.dart' show ClosedWorld;
import 'jump_handler.dart';
import 'locals_handler.dart';
import 'nodes.dart';
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
  Compiler get compiler;

  /// True if the builder is processing nodes inside a try statement. This is
  /// important for generating control flow out of a try block like returns or
  /// breaks.
  bool inTryStatement = false;

  /// The tree elements for the element being built into an SSA graph.
  TreeElements get elements;

  /// The JavaScript backend we are targeting in this compilation.
  JavaScriptBackend get backend;

  CodegenRegistry get registry;

  ClosedWorld get closedWorld;

  CommonMasks get commonMasks => closedWorld.commonMasks;

  DiagnosticReporter get reporter => backend.reporter;

  CompilerOptions get options => compiler.options;

  CommonElements get commonElements => closedWorld.commonElements;

  CodeEmitterTask get emitter => backend.emitter;

  GlobalTypeInferenceResults get globalInferenceResults =>
      compiler.globalInference.results;

  ClosureDataLookup get closureDataLookup =>
      compiler.backendStrategy.closureDataLookup;

  NativeData get nativeData => closedWorld.nativeData;

  InterceptorData get interceptorData => closedWorld.interceptorData;

  BackendUsage get backendUsage => closedWorld.backendUsage;

  Namer get namer => backend.namer;

  RuntimeTypesNeed get rtiNeed => closedWorld.rtiNeed;

  JavaScriptConstantCompiler get constants => backend.constants;

  ConstantSystem get constantSystem => constants.constantSystem;

  RuntimeTypesEncoder get rtiEncoder => backend.rtiEncoder;

  FunctionInlineCache get inlineCache => backend.inlineCache;

  MirrorsData get mirrorsData => backend.mirrorsData;

  JsInteropAnalysis get jsInteropAnalysis => backend.jsInteropAnalysis;

  DeferredLoadTask get deferredLoadTask => compiler.deferredLoadTask;

  DartTypes get types => closedWorld.dartTypes;

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
    push(new HIdentity(expression, graph.addConstantNull(closedWorld), null,
        closedWorld.commonMasks.boolType));
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

  Map<Local, HInstruction> parameters = <Local, HInstruction>{};

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

  HSubGraphBlockInformation wrapStatementGraph(SubGraph statements) {
    if (statements == null) return null;
    return new HSubGraphBlockInformation(statements);
  }

  HSubExpressionBlockInformation wrapExpressionGraph(SubExpression expression) {
    if (expression == null) return null;
    return new HSubExpressionBlockInformation(expression);
  }

  /// Returns the current source element.
  ///
  /// The returned element is a declaration element.
  MemberEntity get sourceElement;

  // TODO(karlklose): this is needed to avoid a bug where the resolved type is
  // not stored on a type annotation in the closure translator. Remove when
  // fixed.
  bool hasDirectLocal(Local local) {
    return !localsHandler.isAccessedDirectly(local) ||
        localsHandler.directLocals[local] != null;
  }

  HInstruction callSetRuntimeTypeInfoWithTypeArguments(InterfaceType type,
      List<HInstruction> rtiInputs, HInstruction newObject) {
    if (!rtiNeed.classNeedsRti(type.element)) {
      return newObject;
    }

    HInstruction typeInfo = new HTypeInfoExpression(
        TypeInfoExpressionKind.INSTANCE,
        (type.element as ClassElement).thisType,
        rtiInputs,
        closedWorld.commonMasks.dynamicType);
    add(typeInfo);
    return callSetRuntimeTypeInfo(typeInfo, newObject);
  }

  /// Called when control flow is about to change, in which case we need to
  /// specify special successors if we are already in a try/catch/finally block.
  void handleInTryStatement() {
    if (!inTryStatement) return;
    HBasicBlock block = close(new HExitTry());
    HBasicBlock newBlock = graph.addNewBlock();
    block.addSuccessor(newBlock);
    open(newBlock);
  }

  HInstruction callSetRuntimeTypeInfo(
      HInstruction typeInfo, HInstruction newObject);

  /// The element for which this SSA builder is being used.
  MemberEntity get targetElement;
  TypeBuilder get typeBuilder;

  /// Helper to implement JS_GET_FLAG.
  ///
  /// The concrete SSA graph builder will extract a flag parameter from the
  /// JS_GET_FLAG call and then push a boolean result onto the stack. This
  /// function provides the boolean value corresponding to the given [flagName].
  /// If [flagName] is not recognized, this function returns `null` and the
  /// concrete SSA builder reports an error.
  bool getFlagValue(String flagName) {
    switch (flagName) {
      case 'MUST_RETAIN_METADATA':
        return mirrorsData.mustRetainMetadata;
      case 'USE_CONTENT_SECURITY_POLICY':
        return options.useContentSecurityPolicy;
      case 'IS_FULL_EMITTER':
        return !USE_LAZY_EMITTER && !options.useStartupEmitter;
      default:
        return null;
    }
  }
}
