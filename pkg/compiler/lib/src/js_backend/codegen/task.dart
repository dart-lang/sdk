// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generate code using the cps-based IR pipeline.
library code_generator_task;

import 'glue.dart';
import 'codegen.dart';
import 'unsugar.dart';

import '../js_backend.dart';

import '../../common.dart';
import '../../common/codegen.dart' show
    CodegenWorkItem;
import '../../common/tasks.dart' show
    CompilerTask,
    GenericTask;
import '../../compiler.dart' show
    Compiler;
import '../../constants/constant_system.dart';
import '../../cps_ir/cps_ir_builder_task.dart';
import '../../cps_ir/cps_ir_nodes.dart' as cps;
import '../../cps_ir/cps_ir_nodes_sexpr.dart';
import '../../cps_ir/cps_ir_integrity.dart';
import '../../cps_ir/optimizers.dart';
import '../../cps_ir/optimizers.dart' as cps_opt;
import '../../cps_ir/type_mask_system.dart';
import '../../cps_ir/finalize.dart' show Finalize;
import '../../diagnostics/invariant.dart' show
    DEBUG_MODE;
import '../../elements/elements.dart';
import '../../js/js.dart' as js;
import '../../js_backend/codegen/codegen.dart';
import '../../io/source_information.dart' show
    SourceInformationStrategy;
import '../../tree_ir/tree_ir_builder.dart' as tree_builder;
import '../../tracer.dart';
import '../../ssa/ssa.dart' as ssa;
import '../../tree_ir/optimization/optimization.dart';
import '../../tree_ir/optimization/optimization.dart' as tree_opt;
import '../../tree_ir/tree_ir_integrity.dart';
import '../../tree_ir/tree_ir_nodes.dart' as tree_ir;
import '../../types/types.dart' show
    FlatTypeMask,
    ForwardingTypeMask,
    TypeMask,
    UnionTypeMask;

class CpsFunctionCompiler implements FunctionCompiler {
  final ConstantSystem constantSystem;
  // TODO(karlklose): remove the compiler.
  final Compiler compiler;
  final Glue glue;
  final SourceInformationStrategy sourceInformationFactory;

  // TODO(karlklose,sigurdm): remove and update dart-doc of [compile].
  final FunctionCompiler fallbackCompiler;
  TypeMaskSystem typeSystem;

  Tracer get tracer => compiler.tracer;

  final IrBuilderTask cpsBuilderTask;
  final GenericTask cpsOptimizationTask;
  final GenericTask treeBuilderTask;
  final GenericTask treeOptimizationTask;

  Inliner inliner;

  CpsFunctionCompiler(Compiler compiler, JavaScriptBackend backend,
                      SourceInformationStrategy sourceInformationFactory)
      : fallbackCompiler =
            new ssa.SsaFunctionCompiler(backend, sourceInformationFactory),
        cpsBuilderTask = new IrBuilderTask(compiler, sourceInformationFactory),
        sourceInformationFactory = sourceInformationFactory,
        constantSystem = backend.constantSystem,
        compiler = compiler,
        glue = new Glue(compiler),
        cpsOptimizationTask = new GenericTask('CPS optimization', compiler),
        treeBuilderTask = new GenericTask('Tree builder', compiler),
      treeOptimizationTask = new GenericTask('Tree optimization', compiler) {
    inliner = new Inliner(this);
  }

  String get name => 'CPS Ir pipeline';

  JavaScriptBackend get backend => compiler.backend;

  DiagnosticReporter get reporter => compiler.reporter;

  /// Generates JavaScript code for `work.element`.
  js.Fun compile(CodegenWorkItem work) {
    if (typeSystem == null) typeSystem = new TypeMaskSystem(compiler);
    AstElement element = work.element;
    return reporter.withCurrentElement(element, () {
      try {
        // TODO(karlklose): remove this fallback when we do not need it for
        // testing anymore.
        if (false) {
          reporter.log('Using SSA compiler for platform element $element');
          return fallbackCompiler.compile(work);
        }

        if (tracer != null) {
          tracer.traceCompilation('$element', null);
        }
        cps.FunctionDefinition cpsFunction = compileToCpsIr(element);
        optimizeCpsBeforeInlining(cpsFunction);
        applyCpsPass(inliner, cpsFunction);
        optimizeCpsAfterInlining(cpsFunction);
        cpsIntegrityChecker = null;
        tree_ir.FunctionDefinition treeFunction = compileToTreeIr(cpsFunction);
        treeFunction = optimizeTreeIr(treeFunction);
        return compileToJavaScript(work, treeFunction);
      } on CodegenBailout catch (e) {
        String message = "Unable to compile $element with the new compiler.\n"
            "  Reason: ${e.message}";
        reporter.internalError(element, message);
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

  String stringify(cps.FunctionDefinition node) {
    return new SExpressionStringifier().withTypes().visit(node);
  }

  /// For debugging purposes, replace a call to [applyCpsPass] with a call
  /// to [debugCpsPass] to check that this pass is idempotent.
  ///
  /// This runs [pass] followed by shrinking reductions, and then checks that
  /// one more run of [pass] does not change the IR.  The intermediate shrinking
  /// reductions pass is omitted if [pass] itself is shrinking reductions.
  ///
  /// If [targetName] is given, functions whose name contains that substring
  /// will be dumped out if the idempotency test fails.
  void debugCpsPass(cps_opt.Pass makePass(),
                    cps.FunctionDefinition cpsFunction,
                    [String targetName]) {
    String original = stringify(cpsFunction);
    cps_opt.Pass pass = makePass();
    pass.rewrite(cpsFunction);
    assert(checkCpsIntegrity(cpsFunction, pass.passName));
    if (pass is! ShrinkingReducer) {
      new ShrinkingReducer().rewrite(cpsFunction);
    }
    String before = stringify(cpsFunction);
    makePass().rewrite(cpsFunction);
    String after = stringify(cpsFunction);
    if (before != after) {
      print('SExpression changed for ${cpsFunction.element}');
      if (targetName != null && '${cpsFunction.element}'.contains(targetName)) {
        print(original);
        print('\n-->\n');
        print(before);
        print('\n-->\n');
        print(after);
        compiler.outputProvider('original', 'dump')..add(original)..close();
        compiler.outputProvider('before', 'dump')..add(before)..close();
        compiler.outputProvider('after', 'dump')..add(after)..close();
      }
    }
    traceGraph(pass.passName, cpsFunction);
    dumpTypedIr(pass.passName, cpsFunction);
  }

  void applyCpsPass(cps_opt.Pass pass, cps.FunctionDefinition cpsFunction) {
    cpsOptimizationTask.measureSubtask(pass.passName, () {
      pass.rewrite(cpsFunction);
    });
    traceGraph(pass.passName, cpsFunction);
    dumpTypedIr(pass.passName, cpsFunction);
    assert(checkCpsIntegrity(cpsFunction, pass.passName));
  }

  cps.FunctionDefinition compileToCpsIr(AstElement element) {
    cps.FunctionDefinition cpsFunction = inliner.cache.getUnoptimized(element);
    if (cpsFunction != null) return cpsFunction;

    cpsFunction = cpsBuilderTask.buildNode(element, typeSystem);
    if (cpsFunction == null) {
      if (cpsBuilderTask.bailoutMessage == null) {
        giveUp('unable to build cps definition of $element');
      } else {
        giveUp(cpsBuilderTask.bailoutMessage);
      }
    }
    ParentVisitor.setParents(cpsFunction);
    traceGraph('IR Builder', cpsFunction);
    dumpTypedIr('IR Builder', cpsFunction);
    // Eliminating redundant phis before the unsugaring pass will make it
    // insert fewer getInterceptor calls.
    applyCpsPass(new RedundantPhiEliminator(), cpsFunction);
    applyCpsPass(new UnsugarVisitor(glue), cpsFunction);
    applyCpsPass(new RedundantJoinEliminator(), cpsFunction);
    applyCpsPass(new RedundantPhiEliminator(), cpsFunction);
    applyCpsPass(new InsertRefinements(typeSystem), cpsFunction);

    inliner.cache.putUnoptimized(element, cpsFunction);
    return cpsFunction;
  }

  static const Pattern PRINT_TYPED_IR_FILTER = null;

  String formatTypeMask(TypeMask type) {
    if (type is UnionTypeMask) {
      return '[${type.disjointMasks.map(formatTypeMask).join(', ')}]';
    } else if (type is FlatTypeMask) {
      if (type.isEmpty) return "empty";
      if (type.isNull) return "null";
      String suffix = (type.isExact ? "" : "+") + (type.isNullable ? "?" : "!");
      return '${type.base.name}$suffix';
    } else if (type is ForwardingTypeMask) {
      return formatTypeMask(type.forwardTo);
    }
    throw 'unsupported: $type';
  }

  void dumpTypedIr(String passName, cps.FunctionDefinition cpsFunction) {
    if (PRINT_TYPED_IR_FILTER != null &&
        PRINT_TYPED_IR_FILTER.matchAsPrefix(cpsFunction.element.name) != null) {
      String printType(nodeOrRef, String s) {
        cps.Node node = nodeOrRef is cps.Reference
            ? nodeOrRef.definition
            : nodeOrRef;
        return node is cps.Variable && node.type != null
            ? '$s:${formatTypeMask(node.type)}'
            : s;
      }
      DEBUG_MODE = true;
      print(';;; ==== After $passName ====');
      print(new SExpressionStringifier(printType).visit(cpsFunction));
    }
  }

  CheckCpsIntegrity cpsIntegrityChecker;

  bool checkCpsIntegrity(cps.FunctionDefinition node, String previousPass) {
    cpsOptimizationTask.measureSubtask('Check integrity', () {
      if (cpsIntegrityChecker == null) {
        cpsIntegrityChecker = new CheckCpsIntegrity();
      }
      cpsIntegrityChecker.check(node, previousPass);
    });
    return true; // So this can be used from assert().
  }

  void optimizeCpsBeforeInlining(cps.FunctionDefinition cpsFunction) {
    cpsOptimizationTask.measure(() {
      applyCpsPass(new TypePropagator(this), cpsFunction);
      applyCpsPass(new RedundantJoinEliminator(), cpsFunction);
      applyCpsPass(new ShrinkingReducer(), cpsFunction);
    });
  }

  void optimizeCpsAfterInlining(cps.FunctionDefinition cpsFunction) {
    cpsOptimizationTask.measure(() {
      applyCpsPass(new RedundantJoinEliminator(), cpsFunction);
      applyCpsPass(new ShrinkingReducer(), cpsFunction);
      applyCpsPass(new RedundantRefinementEliminator(typeSystem), cpsFunction);
      applyCpsPass(new UpdateRefinements(typeSystem), cpsFunction);
      applyCpsPass(new TypePropagator(this, recomputeAll: true), cpsFunction);
      applyCpsPass(new ShrinkingReducer(), cpsFunction);
      applyCpsPass(new EagerlyLoadStatics(), cpsFunction);
      applyCpsPass(new GVN(compiler, typeSystem), cpsFunction);
      applyCpsPass(new PathBasedOptimizer(backend, typeSystem), cpsFunction);
      applyCpsPass(new ShrinkingReducer(), cpsFunction);
      applyCpsPass(new UpdateRefinements(typeSystem), cpsFunction);
      applyCpsPass(new BoundsChecker(typeSystem, compiler.world), cpsFunction);
      applyCpsPass(new LoopInvariantBranchMotion(), cpsFunction);
      applyCpsPass(new ShrinkingReducer(), cpsFunction);
      applyCpsPass(new ScalarReplacer(compiler), cpsFunction);
      applyCpsPass(new UseFieldInitializers(backend), cpsFunction);
      applyCpsPass(new MutableVariableEliminator(), cpsFunction);
      applyCpsPass(new RedundantJoinEliminator(), cpsFunction);
      applyCpsPass(new RedundantPhiEliminator(), cpsFunction);
      applyCpsPass(new UpdateRefinements(typeSystem), cpsFunction);
      applyCpsPass(new ShrinkingReducer(), cpsFunction);
      applyCpsPass(new OptimizeInterceptors(backend, typeSystem), cpsFunction);
      applyCpsPass(new BackwardNullCheckRemover(typeSystem), cpsFunction);
      applyCpsPass(new ShrinkingReducer(), cpsFunction);
    });
  }

  tree_ir.FunctionDefinition compileToTreeIr(cps.FunctionDefinition cpsNode) {
    applyCpsPass(new Finalize(backend), cpsNode);
    tree_builder.Builder builder = new tree_builder.Builder(
        reporter.internalError);
    tree_ir.FunctionDefinition treeNode =
        treeBuilderTask.measure(() => builder.buildFunction(cpsNode));
    assert(treeNode != null);
    traceGraph('Tree builder', treeNode);
    assert(checkTreeIntegrity(treeNode));
    return treeNode;
  }

  bool checkTreeIntegrity(tree_ir.FunctionDefinition node) {
    treeOptimizationTask.measureSubtask('Check integrity', () {
      new CheckTreeIntegrity().check(node);
    });
    return true; // So this can be used from assert().
  }

  tree_ir.FunctionDefinition optimizeTreeIr(tree_ir.FunctionDefinition node) {
    void applyTreePass(tree_opt.Pass pass) {
      treeOptimizationTask.measureSubtask(pass.passName, () {
        pass.rewrite(node);
      });
      traceGraph(pass.passName, node);
      assert(checkTreeIntegrity(node));
    }

    treeOptimizationTask.measure(() {
      applyTreePass(new StatementRewriter());
      applyTreePass(new VariableMerger(minifying: compiler.enableMinification));
      applyTreePass(new LoopRewriter());
      applyTreePass(new LogicalRewriter());
      applyTreePass(new PullIntoInitializers());
    });

    return node;
  }

  js.Fun compileToJavaScript(CodegenWorkItem work,
                             tree_ir.FunctionDefinition definition) {
    CodeGenerator codeGen = new CodeGenerator(glue, work.registry);
    Element element = work.element;
    js.Fun code = codeGen.buildFunction(definition);
    if (element is FunctionElement && element.asyncMarker != AsyncMarker.SYNC) {
      code = backend.rewriteAsync(element, code);
      work.registry.registerAsyncMarker(element);
    }
    return attachPosition(code, element);
  }

  Iterable<CompilerTask> get tasks {
    return <CompilerTask>[
        cpsBuilderTask,
        cpsOptimizationTask,
        treeBuilderTask,
        treeOptimizationTask]
      ..addAll(fallbackCompiler.tasks);
  }

  js.Node attachPosition(js.Node node, AstElement element) {
    return node.withSourceInformation(
        sourceInformationFactory.createBuilderForContext(element)
            .buildDeclaration(element));
  }
}
