// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:kernel/ast.dart" show DartType, Library;

import "package:kernel/target/targets.dart" show NoneTarget, TargetFlags;

import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions;

import "package:front_end/src/base/processed_options.dart"
    show ProcessedOptions;

import "package:front_end/src/fasta/builder/class_builder.dart";

import "package:front_end/src/fasta/compiler_context.dart" show CompilerContext;

import "package:front_end/src/fasta/dill/dill_loader.dart" show DillLoader;

import "package:front_end/src/fasta/dill/dill_target.dart" show DillTarget;

import "package:front_end/src/fasta/kernel/kernel_builder.dart"
    show ClassHierarchyBuilder;

import "package:front_end/src/fasta/ticker.dart" show Ticker;

import "legacy_upper_bound_helper.dart" show LegacyUpperBoundTest;

class FastaLegacyUpperBoundTest extends LegacyUpperBoundTest {
  final Ticker ticker;
  final CompilerContext context;

  ClassHierarchyBuilder hierarchy;

  FastaLegacyUpperBoundTest(this.ticker, this.context);

  @override
  bool get isNonNullableByDefault => false;

  @override
  Future<void> parseComponent(String source) async {
    await super.parseComponent(source);

    DillTarget target = new DillTarget(
        ticker,
        await context.options.getUriTranslator(),
        new NoneTarget(new TargetFlags()));
    final DillLoader loader = target.loader;
    loader.appendLibraries(env.component);
    await target.buildOutlines();
    ClassBuilder objectClass =
        loader.coreLibrary.lookupLocalMember("Object", required: true);
    hierarchy = new ClassHierarchyBuilder(objectClass, loader, env.coreTypes);
  }

  @override
  DartType getLegacyLeastUpperBound(
      DartType a, DartType b, Library clientLibrary) {
    return hierarchy.getLegacyLeastUpperBound(a, b, clientLibrary);
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
