// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/front_end/ast_to_ir.dart';
import 'package:cfg/front_end/computed_scopes.dart';
import 'package:cfg/ir/ssa_computation.dart';
import 'package:cfg/passes/constant_propagation.dart';
import 'package:cfg/passes/control_flow_optimizations.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/passes/simplification.dart';
import 'package:cfg/passes/value_numbering.dart';
import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import '../code_generator.dart';
import '../intrinsics.dart';
import '../reference_extensions.dart';
import '../translator.dart';
import '../util.dart';
import 'to_wasm.dart';

bool mayUseCfgToCompileMember(Translator translator, Member member) {
  if (!translator.options.useCfg) return false;
  if (member is! Procedure) return false;
  if (member.function.asyncMarker != AsyncMarker.Sync) return false;

  final hasCfgPragma = hasWasmCfgPragma(translator.coreTypes, member);
  if (member.isExternal ||
      StaticIntrinsic.fromProcedure(translator.coreTypes, member) != null ||
      MemberIntrinsic.fromProcedure(translator.coreTypes, member) != null) {
    if (hasCfgPragma) {
      throw StateError(
        'Member $member has @pragma("wasm:cfg") but is '
        '${member.isExternal ? 'external' : 'an intrinsic'}.',
      );
    }
    return false;
  }

  // Avoid compiling platform libraries (`dart:*`) with CFG as the CFG
  // pipeline is still under development and only supports a subset of
  // constructs, unless explicitly requested via `@pragma('wasm:cfg')`.
  if (member.enclosingLibrary.importUri.isScheme('dart') && !hasCfgPragma) {
    return false;
  }

  return true;
}

class CfgProcedureCodeGenerator implements CodeGenerator {
  final SynchronousProcedureCodeGenerator fallback;

  CfgProcedureCodeGenerator(this.fallback);

  Translator get translator => fallback.translator;
  w.FunctionType get functionType => fallback.functionType;
  Procedure get member => fallback.member;
  Reference get reference => fallback.reference;
  EntryPoint get kind => fallback.kind;

  @override
  void generate(
    w.InstructionsBuilder b,
    List<w.Local> paramLocals,
    w.Label? returnLabel,
  ) {
    assert(returnLabel == null);
    assert(translator.options.useCfg);
    final allowFallback = !hasWasmCfgPragma(translator.coreTypes, member);

    if (allowFallback) {
      try {
        if (_tryGenerate(b, paramLocals, returnLabel)) return;
      } catch (_) {}
      b.reset();
      fallback.generate(b, paramLocals, returnLabel);
    } else {
      if (!_tryGenerate(b, paramLocals, returnLabel)) {
        throw StateError(
          'Member $member ($reference) has @pragma("wasm:cfg") but failed to compile with CFG.',
        );
      }
    }
  }

  bool _tryGenerate(
    w.InstructionsBuilder b,
    List<w.Local> paramLocals,
    w.Label? returnLabel,
  ) {
    final cFunction = translator.functionRegistry.getFunction(
      member,
      isGetter: member.isGetter,
      isSetter: member.isSetter,
    );

    final graph = AstToIr(
      cFunction,
      translator.functionRegistry,
      translator.recognizedMethods,
      onLocalFunction: (_) {},
      enableAsserts: translator.options.enableAsserts,
      typeParametersStyle: .separateFunctionAndClassTypeParameters,
      scopes: ComputedScopes(
        member,
        enableAsserts: translator.options.enableAsserts,
      ),
    ).buildFlowGraph();

    final pipeline = Pipeline([
      SSAComputation(),
      ValueNumbering(simplification: Simplification()),
      ConstantPropagation(),
      ControlFlowOptimizations(),
    ]);

    pipeline.run(graph);

    final cfgToWasm = CfgToWasm(
      translator,
      functionType,
      member,
      graph,
      b,
      paramLocals,
      returnLabel,
      kind,
    );

    if (!cfgToWasm.canTranslate()) {
      return false;
    }

    cfgToWasm.generate();
    return true;
  }
}
