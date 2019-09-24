// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.incremental_dynamic_test;

import 'package:async_helper/async_helper.dart' show asyncTest;

import 'package:expect/expect.dart' show Expect;

import 'package:kernel/ast.dart' show Component;

import 'package:kernel/target/targets.dart' show TargetFlags;

import 'package:vm/target/vm.dart' show VmTarget;

import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions, DiagnosticMessage;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

void diagnosticMessageHandler(DiagnosticMessage message) {
  throw "Unexpected message: ${message.plainTextFormatted.join('\n')}";
}

test({bool sdkFromSource}) async {
  final CompilerOptions optionBuilder = new CompilerOptions()
    ..packagesFileUri = Uri.base.resolve(".packages")
    ..target = new VmTarget(new TargetFlags())
    ..omitPlatform = true
    ..onDiagnostic = diagnosticMessageHandler
    ..environmentDefines = const {};

  if (sdkFromSource) {
    optionBuilder.librariesSpecificationUri =
        Uri.base.resolve("sdk/lib/libraries.json");
  } else {
    optionBuilder.sdkSummary =
        computePlatformBinariesLocation(forceBuildDir: true)
            .resolve("vm_platform_strong.dill");
  }

  final Uri helloDart =
      Uri.base.resolve("pkg/front_end/testcases/general/hello.dart");

  final ProcessedOptions options =
      new ProcessedOptions(options: optionBuilder, inputs: [helloDart]);

  IncrementalCompiler compiler =
      new IncrementalCompiler(new CompilerContext(options));

  Component component = await compiler.computeDelta();

  if (sdkFromSource) {
    // Expect that the new component contains at least the following libraries:
    // dart:core, dart:async, and hello.dart.
    Expect.isTrue(
        component.libraries.length > 2, "${component.libraries.length} <= 2");
  } else {
    // Expect that the new component contains exactly hello.dart.
    Expect.isTrue(
        component.libraries.length == 1, "${component.libraries.length} != 1");
  }

  compiler.invalidate(helloDart);

  component = await compiler.computeDelta(entryPoints: [helloDart]);
  // Expect that the new component contains exactly hello.dart
  Expect.isTrue(
      component.libraries.length == 1, "${component.libraries.length} != 1");

  component = await compiler.computeDelta(entryPoints: [helloDart]);
  Expect.isTrue(component.libraries.isEmpty);
}

void main() {
  asyncTest(() async {
    await test(sdkFromSource: true);
    await test(sdkFromSource: false);
  });
}
