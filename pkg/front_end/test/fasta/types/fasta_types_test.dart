// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart" show asyncTest;

import "package:kernel/ast.dart" show Component, DartType;

import "package:kernel/core_types.dart" show CoreTypes;

import "package:kernel/target/targets.dart" show NoneTarget, TargetFlags;

import 'package:kernel/testing/type_parser_environment.dart'
    show TypeParserEnvironment;

import 'package:kernel/type_environment.dart';

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

import 'kernel_type_parser_test.dart' show parseSdk;

import "shared_type_tests.dart" show SubtypeTest;

main() {
  final Ticker ticker = new Ticker(isVerbose: false);
  final CompilerContext context = new CompilerContext(new ProcessedOptions(
      options: new CompilerOptions()
        ..packagesFileUri = Uri.base.resolve(".packages")));
  final Uri uri = Uri.parse("dart:core");
  final TypeParserEnvironment environment = new TypeParserEnvironment(uri, uri);
  final Component sdk = parseSdk(uri, environment);
  Future<void> doIt(_) async {
    DillTarget target = new DillTarget(
        ticker,
        await context.options.getUriTranslator(),
        new NoneTarget(new TargetFlags()));
    final DillLoader loader = target.loader;
    loader.appendLibraries(sdk);
    await target.buildOutlines();
    ClassBuilder objectClass =
        loader.coreLibrary.lookupLocalMember("Object", required: true);
    ClassHierarchyBuilder hierarchy =
        new ClassHierarchyBuilder(objectClass, loader, new CoreTypes(sdk));
    new FastaTypesTest(hierarchy, environment).run();
  }

  asyncTest(() => context.runInContext<void>(doIt));
}

class FastaTypesTest extends SubtypeTest<DartType, TypeParserEnvironment> {
  final ClassHierarchyBuilder hierarchy;

  final TypeParserEnvironment environment;

  FastaTypesTest(this.hierarchy, this.environment);

  DartType toType(String text, TypeParserEnvironment environment) {
    return environment.parseType(text);
  }

  IsSubtypeOf isSubtypeImpl(DartType subtype, DartType supertype) {
    return hierarchy.types
        .performNullabilityAwareSubtypeCheck(subtype, supertype);
  }

  TypeParserEnvironment extend(String typeParameters) {
    return environment.extendWithTypeParameters(typeParameters);
  }
}
