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

  // TODO(sigurdm): Assign this.
  Tracer tracer;

  String get name => 'CPS Ir pipeline';

  final IrBuilderTask irBuilderTask;

  final ConstantSystem constantSystem;

  final Compiler compiler;

  // Remember to update dart-doc of [compile] when this field is removed.
  FunctionCompiler fallbackCompiler;

  CspFunctionCompiler(Compiler compiler, JavaScriptBackend backend)
      : irBuilderTask = new IrBuilderTask(compiler),
        fallbackCompiler = new ssa.SsaFunctionCompiler(backend),
        constantSystem = backend.constantSystem,
        compiler = compiler;

  /// Generates JavaScript code for `work.element`. First tries to use the
  /// Cps Ir -> tree ir -> js pipeline, and if that fails due to language
  /// features not implemented it will fall back to the ssa pipeline.
  js.Fun compile(CodegenWorkItem work) {
    AstElement element = work.element;
      return compiler.withCurrentElement(element, () {
        try {
        // TODO(sigurdm): Support these constructs.
        if(work.element.isGenerativeConstructorBody ||
           work.element.enclosingClass is ClosureClassElement ||
           work.element.isNative) {
          throw CodeGenerator.UNIMPLEMENTED;
        }

        void traceGraph(String title, var irObject) {
          if (tracer != null) {
            tracer.traceGraph(title, irObject);
          }
        }

        cps.FunctionDefinition cps_definition =
            irBuilderTask.buildNode(element);
        if (cps_definition == null) throw CodeGenerator.UNIMPLEMENTED;
        if (tracer != null) {
          tracer.traceCompilation(element.name, null);
        }
        // Transformations on the CPS IR.
        traceGraph("IR Builder", cps_definition);
        new ConstantPropagator(compiler, constantSystem)
            .rewrite(cps_definition);
        traceGraph("Sparse constant propagation", cps_definition);
        new RedundantPhiEliminator().rewrite(cps_definition);
        traceGraph("Redundant phi elimination", cps_definition);
        new ShrinkingReducer().rewrite(cps_definition);
        traceGraph("Shrinking reductions", cps_definition);

        // Do not rewrite the IR after variable allocation.  Allocation
        // makes decisions based on an approximation of IR variable live
        // ranges that can be invalidated by transforming the IR.
        new cps.RegisterAllocator().visit(cps_definition);

        tree_builder.Builder builder = new tree_builder.Builder(compiler);
        tree_ir.FunctionDefinition definition = builder.build(cps_definition);
        assert(definition != null);
        traceGraph('Tree builder', definition);

        // Transformations on the Tree IR.
        new StatementRewriter().rewrite(definition);
        traceGraph('Statement rewriter', definition);
        new CopyPropagator().rewrite(definition);
        traceGraph('Copy propagation', definition);
        new LoopRewriter().rewrite(definition);
        traceGraph('Loop rewriter', definition);
        new LogicalRewriter().rewrite(definition);
        traceGraph('Logical rewriter', definition);
        new backend_ast_emitter.UnshadowParameters().unshadow(definition);
        traceGraph('Unshadow parameters', definition);

        CodeGenerator codeGen = new CodeGenerator();

        codeGen.buildFunction(definition);
        return buildJavaScriptFunction(work.element,
                                       codeGen.parameters,
                                       codeGen.body);
      } catch (e, tr) {
        if (e == CodeGenerator.UNIMPLEMENTED) {
          return fallbackCompiler.compile(work);
        } else {
          rethrow;
        }
      }
    });
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
