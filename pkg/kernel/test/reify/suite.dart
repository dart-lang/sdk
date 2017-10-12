// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library test.kernel.reify.suite;

import 'dart:async' show Future;

import 'dart:io' show Platform, File;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/target/targets.dart' show Target, TargetFlags, getTarget;

import 'package:kernel/target/vmcc.dart' show VmClosureConvertedTarget;

import 'package:front_end/src/fasta/testing/kernel_chain.dart'
    show
        Compile,
        CompileContext,
        MatchExpectation,
        Print,
        ReadDill,
        Verify,
        WriteDill;

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, StdioProcess, Step, runMe;

import 'package:kernel/ast.dart' show Program;

import 'package:kernel/transformations/generic_types_reification.dart'
    as generic_types_reification;

class TestContext extends ChainContext implements CompileContext {
  final Uri vm;
  final Uri platformUri;
  final Uri sdk;

  @override
  final Target target = new NotReifiedTarget(new TargetFlags(
      strongMode: true,
      kernelRuntime: Platform.script.resolve("../../runtime/")));

  // Strong mode is required to keep the type arguments in invocations of
  // generic methods.
  @override
  bool get strongMode => true;

  final List<Step> steps;

  TestContext(this.vm, this.platformUri, this.sdk, bool updateExpectations)
      : steps = <Step>[
          const Compile(),
          const Print(),
          const Verify(true),
          const GenericTypesReification(),
          const Print(),
          const Verify(true),
          new MatchExpectation(".expect",
              updateExpectations: updateExpectations),
          const WriteDill(),
          const ReadDill(),
          const Run(),
        ];
}

enum Environment {
  directory,
  file,
}

Future<TestContext> createContext(
    Chain suite, Map<String, String> environment) async {
  Uri vm = Uri.base.resolve(Platform.resolvedExecutable);
  Uri sdk = vm.resolve("patched_sdk/");
  Uri platform = vm.resolve("vm_platform.dill");
  bool updateExpectations = environment["updateExpectations"] == "true";
  return new TestContext(vm, platform, sdk, updateExpectations);
}

// [NotReifiedTarget] is intended to work as the [Target] class that
// [VmGenericTypesReifiedTarget] inherits from, but with some transformations
// disabled. Those include tree shaking and generic types information erasure
// passes.
// [NotReifiedTarget] also adds the necessary runtime libraries.
class NotReifiedTarget extends VmClosureConvertedTarget {
  NotReifiedTarget(TargetFlags flags) : super(flags);

  @override
  String get name => "not reified target";

  // Tree shaking needs to be disabled, because Generic Types Reification
  // transformation relies on certain runtime libraries to be present in
  // the program that is being transformed. If the tree shaker is enabled,
  // it just deletes everything from those libraries, because they aren't
  // used in the program being transform prior to the transformation.
  @override
  void performTreeShaking(CoreTypes coreTypes, Program program) {}

  // Erasure needs to be disabled, because it removes the necessary information
  // about type arguments for generic methods.
  @override
  void performErasure(Program program) {}

  // Adds the necessary runtime libraries.
  @override
  List<String> get extraRequiredLibraries {
    Target reifyTarget = getTarget("vmreify", this.flags);
    var x = reifyTarget.extraRequiredLibraries;
    return x;
  }
}

class GenericTypesReification extends Step<Program, Program, TestContext> {
  const GenericTypesReification();

  String get name => "generic types reification";

  Future<Result<Program>> run(Program program, TestContext testContext) async {
    try {
      CoreTypes coreTypes = new CoreTypes(program);
      program = generic_types_reification.transformProgram(coreTypes, program);
      return pass(program);
    } catch (e, s) {
      return crash(e, s);
    }
  }
}

class Run extends Step<Uri, int, TestContext> {
  const Run();

  String get name => "run";

  bool get isAsync => true;

  bool get isRuntime => true;

  Future<Result<int>> run(Uri uri, TestContext context) async {
    File generated = new File.fromUri(uri);
    StdioProcess process;
    try {
      var sdkPath = context.sdk.toFilePath();
      var args = ['--kernel-binaries=$sdkPath', generated.path];
      process = await StdioProcess.run(context.vm.toFilePath(), args);
      print(process.output);
    } finally {
      generated.parent.delete(recursive: true);
    }
    return process.toResult();
  }
}

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
