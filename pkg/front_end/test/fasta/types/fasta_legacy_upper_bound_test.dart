// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:kernel/ast.dart" show DartType;

import "package:kernel/core_types.dart" show CoreTypes;

import "package:kernel/target/targets.dart" show NoneTarget, TargetFlags;

import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions;

import "package:front_end/src/base/processed_options.dart"
    show ProcessedOptions;

import "package:front_end/src/fasta/compiler_context.dart" show CompilerContext;

import "package:front_end/src/fasta/dill/dill_loader.dart" show DillLoader;

import "package:front_end/src/fasta/dill/dill_target.dart" show DillTarget;

import "package:front_end/src/fasta/kernel/kernel_builder.dart"
    show ClassHierarchyBuilder, KernelClassBuilder;

import "package:front_end/src/fasta/ticker.dart" show Ticker;

import "legacy_upper_bound_helper.dart" show LegacyUpperBoundTest;

class FastaLegacyUpperBoundTest extends LegacyUpperBoundTest {
  final Ticker ticker;
  final CompilerContext context;

  ClassHierarchyBuilder hierarchy;

  FastaLegacyUpperBoundTest(this.ticker, this.context);

  @override
  Future<void> parseComponent(String source) async {
    await super.parseComponent(source);

    DillTarget target = new DillTarget(
        ticker,
        await context.options.getUriTranslator(),
        new NoneTarget(new TargetFlags()));
    final DillLoader loader = target.loader;
    loader.appendLibraries(component);
    await target.buildOutlines();
    KernelClassBuilder objectClass = loader.coreLibrary["Object"];
    hierarchy = new ClassHierarchyBuilder(
        objectClass, loader, new CoreTypes(component));
  }

  @override
  DartType getLegacyLeastUpperBound(DartType a, DartType b) {
    return hierarchy.getKernelLegacyLeastUpperBound(a, b);
  }
}

main() {
  final Ticker ticker = new Ticker();
  final CompilerContext context = new CompilerContext(new ProcessedOptions(
      options: new CompilerOptions()
        ..packagesFileUri = Uri.base.resolve(".packages")));
  context.runInContext<void>(
      (_) => new FastaLegacyUpperBoundTest(ticker, context).test());
}
