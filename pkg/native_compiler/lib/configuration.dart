// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph_checker.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/ir_to_text.dart';
import 'package:cfg/ir/ssa_computation.dart';
import 'package:cfg/passes/constant_propagation.dart';
import 'package:cfg/passes/control_flow_optimizations.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/passes/simplification.dart';
import 'package:cfg/passes/value_numbering.dart';
import 'package:native_compiler/back_end/arm64/code_generator.dart';
import 'package:native_compiler/back_end/arm64/constraints.dart';
import 'package:native_compiler/back_end/arm64/stack_frame.dart';
import 'package:native_compiler/back_end/arm64/stub_code_generator.dart';
import 'package:native_compiler/back_end/back_end_state.dart';
import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/code_generator.dart';
import 'package:native_compiler/back_end/constraints.dart';
import 'package:native_compiler/back_end/regalloc_checker.dart';
import 'package:native_compiler/back_end/register_allocator.dart';
import 'package:native_compiler/back_end/stack_frame.dart';
import 'package:native_compiler/back_end/stub_code_generator.dart';
import 'package:native_compiler/passes/lowering.dart';
import 'package:native_compiler/passes/reorder_blocks.dart';
import 'package:native_compiler/passes/unboxing.dart';
import 'package:native_compiler/runtime/object_layout.dart';
import 'package:native_compiler/runtime/vm_defs.dart';
import 'package:native_compiler/snapshot/image_writer.dart';
import 'package:native_compiler/snapshot/macho/macho_image_writer.dart';

enum TargetCPU {
  arm64;

  static final String defaultName = arm64.name;
  static final List<String> allowedNames = [for (final v in values) v.name];
  static TargetCPU fromName(String name) => values.byName(name);
}

enum ImageFormat {
  macho;

  static final String defaultName = macho.name;
  static final List<String> allowedNames = [for (final v in values) v.name];
  static ImageFormat fromName(String name) => values.byName(name);
}

abstract base class Configuration(
  final TargetCPU targetCPU,
  final ImageFormat imageFormat, {
  required final bool enableAsserts,
  required final bool useAstScopes,
  required final String outputLibraryName,
  required final String? printFlowGraph,
  required final bool printFlowGraphAfterEveryPass,
  required final bool printRegisterAllocation,
}) {
  VMOffsets get vmOffsets;

  ObjectLayout get objectLayout;

  Pipeline createPipeline(
    CFunction function,
    FunctionRegistry functionRegistry,
    StubFactory stubFactory,
    CodeConsumer consumeGeneratedCode,
  );

  Constraints createConstraints() => switch (targetCPU) {
    TargetCPU.arm64 => Arm64Constraints(),
  };

  StackFrame createStackFrame(CFunction function) => switch (targetCPU) {
    TargetCPU.arm64 => Arm64StackFrame(function),
  };

  CodeGenerator createCodeGenerator(
    BackEndState backEndState,
    FunctionRegistry functionRegistry,
  ) => switch (targetCPU) {
    TargetCPU.arm64 => Arm64CodeGenerator(backEndState, functionRegistry),
  };

  StubFactory createStubFactory(CodeConsumer consumeGeneratedCode) =>
      switch (targetCPU) {
        TargetCPU.arm64 => Arm64StubFactory(
          vmOffsets,
          objectLayout,
          consumeGeneratedCode,
        ),
      };

  ImageWriter createImageWriter() => switch (imageFormat) {
    ImageFormat.macho => MachoImageWriter(targetCPU, outputLibraryName),
  };

  bool printFlowGraphFor(CFunction function) =>
      printFlowGraph != null && function.toString().contains(printFlowGraph!);
}

final class DevelopmentCompilerConfiguration extends Configuration {
  DevelopmentCompilerConfiguration(
    super.targetCPU,
    super.imageFormat, {
    required super.enableAsserts,
    required super.useAstScopes,
    required super.outputLibraryName,
    required super.printFlowGraph,
    required super.printFlowGraphAfterEveryPass,
    required super.printRegisterAllocation,
  });

  @override
  late final VMOffsets vmOffsets = switch (targetCPU) {
    TargetCPU.arm64 => Arm64VMOffsets(),
  };

  @override
  late final ObjectLayout objectLayout = switch (targetCPU) {
    TargetCPU.arm64 => ObjectLayout(
      vmOffsets,
      wordSize: 8,
      compressedWordSize: 8,
    ),
  };

  @override
  Pipeline createPipeline(
    CFunction function,
    FunctionRegistry functionRegistry,
    StubFactory stubFactory,
    CodeConsumer consumeGeneratedCode,
  ) {
    final unboxing = Unboxing();
    final backEndState = BackEndState();
    backEndState.vmOffsets = vmOffsets;
    backEndState.objectLayout = objectLayout;
    backEndState.stubFactory = stubFactory;
    backEndState.unboxing = unboxing;
    backEndState.stackFrame = createStackFrame(function);
    backEndState.consumeGeneratedCode = consumeGeneratedCode;
    final constraints = createConstraints();

    void Function(Pass)? afterPass;
    if (printFlowGraphFor(function)) {
      afterPass = (Pass pass) {
        if ((printFlowGraphAfterEveryPass && pass is! FlowGraphChecker) ||
            pass is CodeGenerator) {
          var annotator = pass.errorContext.annotator;
          if (printRegisterAllocation && pass is CodeGenerator) {
            annotator = RegisterAllocationPrinter(
              backEndState,
              constraints,
            ).print;
          }
          print('CFG IR of $function after ${pass.name}');
          print(IrToText(pass.graph, annotator: annotator));
        }
      };
    }

    return Pipeline([
      SSAComputation(),
      ValueNumbering(simplification: Simplification()),
      ConstantPropagation(),
      ControlFlowOptimizations(),
      Lowering(functionRegistry, objectLayout),
      unboxing,
      ValueNumbering(simplification: Simplification()),
      ReorderBlocks(backEndState),
      LinearScanRegisterAllocator(backEndState, constraints),
      RegisterAllocationChecker(backEndState, constraints),
      createCodeGenerator(backEndState, functionRegistry),
    ], afterPass: afterPass);
  }
}
