// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/options.dart';
import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/codegen.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/types.dart';
import '../js_model/js_world.dart';
import 'nodes.dart';
import 'jump_handler.dart';
import 'locals_handler.dart';

abstract class KernelSsaGraphBuilder extends ir.Visitor<void> {
  JClosedWorld get closedWorld;

  GlobalTypeInferenceResults get globalInferenceResults;

  Map<Local, HInstruction> get parameters;

  HGraph get graph;

  Map<JumpTarget, JumpHandler> get jumpTargets;

  LocalsHandler get localsHandler;

  List<HInstruction> get stack;
  set localsHandler(LocalsHandler handler);

  CodegenRegistry get registry;

  CompilerOptions get options;

  MemberEntity get targetElement;

  DiagnosticReporter get reporter;

  MemberEntity get sourceElement;

  HLocalValue? get lastAddedParameter;
  set lastAddedParameter(HLocalValue? parameter);

  HBasicBlock? get current;

  int get loopDepth;
  set loopDepth(int depth);

  HBasicBlock get lastOpenedBlock;

  set elidedParameters(Set<Local> elidedParameters);

  void add(HInstruction box);

  HLocalValue addParameter(Local contextBox, AbstractValue nonNullType,
      {bool isElided = false});

  HBasicBlock close(HControlFlow end);

  HInstruction pop();

  HBasicBlock openNewBlock();

  bool isAborted();

  HBasicBlock addNewBlock();

  void open(HBasicBlock beginBodyBlock);

  HExpressionInformation wrapExpressionGraph(SubExpression initializerGraph);

  HStatementInformation wrapStatementGraph(SubGraph bodyGraph);

  JumpHandler createJumpHandler(ir.TreeNode node, JumpTarget? jumpTarget,
      {required bool isLoopJump});

  HInstruction popBoolified();

  void goto(HBasicBlock current, HBasicBlock block);

  void pushCheckNull(HInstruction leftExpression);

  void push(HNot hNot);
}
