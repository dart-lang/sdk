// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart" show asyncTest;

import "package:kernel/ast.dart" show Component, DartType;

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

import "kernel_type_parser.dart" show KernelEnvironment, KernelFromParsedType;

import "kernel_type_parser_test.dart" show parseSdk;

import "shared_type_tests.dart" show SubtypeTest;

import "type_parser.dart" as type_parser show parse, parseTypeVariables;

main() {
  final Ticker ticker = new Ticker(isVerbose: false);
  final CompilerContext context = new CompilerContext(new ProcessedOptions(
      options: new CompilerOptions()
        ..packagesFileUri = Uri.base.resolve(".packages")));
  final Uri uri = Uri.parse("dart:core");
  final KernelEnvironment environment = new KernelEnvironment(uri, uri);
  final Component sdk = parseSdk(uri, environment);
  Future<void> doIt(_) async {
    DillTarget target = new DillTarget(
        ticker,
        await context.options.getUriTranslator(),
        new NoneTarget(new TargetFlags()));
    final DillLoader loader = target.loader;
    loader.appendLibraries(sdk);
    await target.buildOutlines();
    KernelClassBuilder objectClass = loader.coreLibrary["Object"];
    ClassHierarchyBuilder hierarchy =
        new ClassHierarchyBuilder(objectClass, loader, new CoreTypes(sdk));
    new FastaTypesTest(hierarchy, environment).run();
  }

  asyncTest(() => context.runInContext<void>(doIt));
}

class FastaTypesTest extends SubtypeTest<DartType, KernelEnvironment> {
  final ClassHierarchyBuilder hierarchy;

  final KernelEnvironment environment;

  FastaTypesTest(this.hierarchy, this.environment);

  DartType toType(String text, KernelEnvironment environment) {
    return environment.kernelFromParsedType(type_parser.parse(text).single);
  }

  bool isSubtypeImpl(DartType subtype, DartType supertype) {
    return hierarchy.types.isSubtypeOfKernel(subtype, supertype);
  }

  KernelEnvironment extend(String typeParameters) {
    if (typeParameters?.isEmpty ?? true) return environment;
    return const KernelFromParsedType()
        .computeTypeParameterEnvironment(
            type_parser.parseTypeVariables("<$typeParameters>"), environment)
        .environment;
  }
}
