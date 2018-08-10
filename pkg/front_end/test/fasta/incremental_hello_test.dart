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
    show CompilerOptions;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/fasta_codes.dart' show FormattedMessage;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import 'package:front_end/src/fasta/severity.dart' show Severity;

void problemHandler(FormattedMessage message, Severity severity,
    List<FormattedMessage> context) {
  throw "Unexpected message: ${message.formatted}";
}

test({bool sdkFromSource}) async {
  final CompilerOptions optionBuilder = new CompilerOptions()
    ..packagesFileUri = Uri.base.resolve(".packages")
    ..target = new VmTarget(new TargetFlags(strongMode: false))
    ..strongMode = false
    ..onProblem = problemHandler;

  if (sdkFromSource) {
    optionBuilder.librariesSpecificationUri =
        Uri.base.resolve("sdk/lib/libraries.json");
  } else {
    optionBuilder.sdkSummary =
        computePlatformBinariesLocation().resolve("vm_platform.dill");
  }

  final Uri helloDart = Uri.base.resolve("pkg/front_end/testcases/hello.dart");

  final ProcessedOptions options =
      new ProcessedOptions(optionBuilder, [helloDart]);

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

  component = await compiler.computeDelta(entryPoint: helloDart);
  // Expect that the new component contains exactly hello.dart
  Expect.isTrue(
      component.libraries.length == 1, "${component.libraries.length} != 1");

  component = await compiler.computeDelta(entryPoint: helloDart);
  Expect.isTrue(component.libraries.isEmpty);
}

void main() {
  asyncTest(() async {
    await test(sdkFromSource: true);
    await test(sdkFromSource: false);
  });
}
