// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generate code using the cps-based IR pipeline.
library code_generator_task;

import '../js_backend.dart';import '../../dart2jslib.dart';
import '../../source_file.dart';
import '../../cps_ir/cps_ir_nodes.dart' as cps;
import '../../cps_ir/cps_ir_builder.dart';
import '../../tree_ir/tree_ir_nodes.dart' as tree_ir;
import '../../tree/tree.dart' as ast;
import '../../scanner/scannerlib.dart' as scanner;
import '../../elements/elements.dart';
import '../../closure.dart';
import '../../js/js.dart' as js;
import '../../source_map_builder.dart';
import '../../tree_ir/tree_ir_builder.dart' as tree_builder;
import '../../dart_backend/backend_ast_emitter.dart' as backend_ast_emitter;
import '../../cps_ir/optimizers.dart';
import '../../tracer.dart';
import '../../dart_backend/statement_rewriter.dart';
import '../../dart_backend/copy_propagator.dart';
import '../../dart_backend/loop_rewriter.dart';
import '../../dart_backend/logical_rewriter.dart';
import '../../js_backend/codegen/codegen.dart';
import '../../ssa/ssa.dart' as ssa;

class CspFunctionCompiler implements FunctionCompiler {
  final IrBuilderTask irBuilderTask;
  final ConstantSystem constantSystem;
  final Compiler compiler;

  // TODO(karlklose,sigurm): remove and update dart-doc of [compile].
  final FunctionCompiler fallbackCompiler;

  // TODO(sigurdm): Assign this.
  Tracer tracer;

  CspFunctionCompiler(Compiler compiler, JavaScriptBackend backend)
      : irBuilderTask = new IrBuilderTask(compiler),
        fallbackCompiler = new ssa.SsaFunctionCompiler(backend, true),
        constantSystem = backend.constantSystem,
        compiler = compiler;

  String get name => 'CPS Ir pipeline';

  /// Generates JavaScript code for `work.element`. First tries to use the
  /// Cps Ir -> tree ir -> js pipeline, and if that fails due to language
  /// features not implemented it will fall back to the ssa pipeline (for
  /// platform code) or will cancel compilation (for user code).
  js.Fun compile(CodegenWorkItem work) {
    AstElement element = work.element;
    return compiler.withCurrentElement(element, () {
      try {
        if (tracer != null) {
          tracer.traceCompilation(element.name, null);
        }
        cps.FunctionDefinition cpsFunction = compileToCpsIR(element);
        cpsFunction = optimizeCpsIR(cpsFunction);
        tree_ir.FunctionDefinition treeFunction = compileToTreeIR(cpsFunction);
        treeFunction = optimizeTreeIR(treeFunction);
        return compileToJavaScript(work, treeFunction);
      } on CodegenBailout catch (e) {
        if (element.library.isPlatformLibrary) {
          compiler.log('Falling back to SSA compiler for $element'
              ' (${e.message})');
          return fallbackCompiler.compile(work);
        } else {
          String message = "Unable to compile $element with the new compiler.\n"
              "  Reason: ${e.message}";
          compiler.internalError(element, message);
        }
      }
    });
  }

  void giveUp(String reason) {
    throw new CodegenBailout(null, reason);
  }

  void traceGraph(String title, var irObject) {
    if (tracer != null) {
      tracer.traceGraph(title, irObject);
    }
  }

  cps.FunctionDefinition compileToCpsIR(AstElement element) {
    // TODO(sigurdm): Support these constructs.
    if (element.isGenerativeConstructorBody ||
        element.enclosingClass is ClosureClassElement ||
        element.isNative) {
      giveUp('unsupported element kind: ${element.name}:${element.kind}');
    }

    cps.FunctionDefinition cpsNode = irBuilderTask.buildNode(element);
    if (cpsNode == null) {
      giveUp('unable to build cps definition of $element');
    }
    return cpsNode;
  }

  cps.FunctionDefinition optimizeCpsIR(cps.FunctionDefinition cpsNode) {
    // Transformations on the CPS IR.
    traceGraph("IR Builder", cpsNode);
    new ConstantPropagator(compiler, constantSystem)
        .rewrite(cpsNode);
    traceGraph("Sparse constant propagation", cpsNode);
    new RedundantPhiEliminator().rewrite(cpsNode);
    traceGraph("Redundant phi elimination", cpsNode);
    new ShrinkingReducer().rewrite(cpsNode);
    traceGraph("Shrinking reductions", cpsNode);

    // Do not rewrite the IR after variable allocation.  Allocation
    // makes decisions based on an approximation of IR variable live
    // ranges that can be invalidated by transforming the IR.
    new cps.RegisterAllocator().visit(cpsNode);
    return cpsNode;
  }

  tree_ir.FunctionDefinition compileToTreeIR(cps.FunctionDefinition cpsNode) {
    tree_builder.Builder builder = new tree_builder.Builder(compiler);
    tree_ir.FunctionDefinition treeNode = builder.build(cpsNode);
    assert(treeNode != null);
    traceGraph('Tree builder', treeNode);
    return treeNode;
  }

  tree_ir.FunctionDefinition optimizeTreeIR(
      tree_ir.FunctionDefinition treeNode) {
    // Transformations on the Tree IR.
    new StatementRewriter().rewrite(treeNode);
    traceGraph('Statement rewriter', treeNode);
    new CopyPropagator().rewrite(treeNode);
    traceGraph('Copy propagation', treeNode);
    new LoopRewriter().rewrite(treeNode);
    traceGraph('Loop rewriter', treeNode);
    new LogicalRewriter().rewrite(treeNode);
    traceGraph('Logical rewriter', treeNode);
    new backend_ast_emitter.UnshadowParameters().unshadow(treeNode);
    traceGraph('Unshadow parameters', treeNode);
    return treeNode;
  }

  js.Fun compileToJavaScript(CodegenWorkItem work,
                             tree_ir.FunctionDefinition definition) {
    CodeGenerator codeGen = new CodeGenerator();

    codeGen.buildFunction(definition);
    return buildJavaScriptFunction(work.element,
                                   codeGen.parameters,
                                   codeGen.body);
  }

  Iterable<CompilerTask> get tasks {
    // TODO(sigurdm): Make a better list of tasks.
    return <CompilerTask>[irBuilderTask]..addAll(fallbackCompiler.tasks);
  }

  js.Node attachPosition(js.Node node, AstElement element) {
    // TODO(sra): Attaching positions might be cleaner if the source position
    // was on a wrapping node.
    SourceFile sourceFile = sourceFileOfElement(element);
    String name = element.name;
    AstElement implementation = element.implementation;
    ast.Node expression = implementation.node;
    scanner.Token beginToken;
    scanner.Token endToken;
    if (expression == null) {
      // Synthesized node. Use the enclosing element for the location.
      beginToken = endToken = element.position;
    } else {
      beginToken = expression.getBeginToken();
      endToken = expression.getEndToken();
    }
    // TODO(podivilov): find the right sourceFile here and remove offset
    // checks below.
    var sourcePosition, endSourcePosition;
    if (beginToken.charOffset < sourceFile.length) {
      sourcePosition =
          new TokenSourceFileLocation(sourceFile, beginToken, name);
    }
    if (endToken.charOffset < sourceFile.length) {
      endSourcePosition =
          new TokenSourceFileLocation(sourceFile, endToken, name);
    }
    return node.withPosition(sourcePosition, endSourcePosition);
  }

  SourceFile sourceFileOfElement(Element element) {
    return element.implementation.compilationUnit.script.file;
  }

  js.Fun buildJavaScriptFunction(FunctionElement element,
                                 List<js.Parameter> parameters,
                                 js.Block body) {
    return attachPosition(new js.Fun(parameters, body), element);
  }
}
