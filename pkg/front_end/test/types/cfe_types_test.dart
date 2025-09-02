// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/async_helper.dart" show asyncTest;
import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions;
import "package:front_end/src/base/compiler_context.dart" show CompilerContext;
import "package:front_end/src/base/processed_options.dart"
    show ProcessedOptions;
import "package:front_end/src/base/ticker.dart" show Ticker;
import "package:front_end/src/builder/declaration_builders.dart";
import "package:front_end/src/dill/dill_loader.dart" show DillLoader;
import "package:front_end/src/dill/dill_target.dart" show DillTarget;
import "package:front_end/src/kernel/hierarchy/hierarchy_builder.dart"
    show ClassHierarchyBuilder;
import "package:kernel/ast.dart" show Component, DartType;
import "package:kernel/core_types.dart" show CoreTypes;
import "package:kernel/target/targets.dart" show NoneTarget, TargetFlags;
import 'package:kernel/testing/type_parser_environment.dart'
    show TypeParserEnvironment;
import 'package:kernel/type_environment.dart';

import 'kernel_type_parser_test.dart' show parseSdk;
import "shared_type_tests.dart" show SubtypeTest;

void main() {
  final Ticker ticker = new Ticker(isVerbose: false);
  final CompilerContext context = new CompilerContext(
    new ProcessedOptions(
      options: new CompilerOptions()
        ..packagesFileUri = Uri.base.resolve(".dart_tool/package_config.json"),
    ),
  );
  final Uri uri = Uri.parse("dart:core");
  final TypeParserEnvironment environment = new TypeParserEnvironment(uri, uri);
  final Component sdk = parseSdk(uri, environment);
  Future<void> doIt(_) async {
    DillTarget target = new DillTarget(
      context,
      ticker,
      await context.options.getUriTranslator(),
      new NoneTarget(new TargetFlags()),
    );
    final DillLoader loader = target.loader;
    loader.appendLibraries(sdk);
    target.buildOutlines();
    ClassBuilder objectClass =
        loader.coreLibrary.lookupRequiredLocalMember("Object") as ClassBuilder;
    ClassHierarchyBuilder hierarchy = new ClassHierarchyBuilder(
      objectClass,
      loader,
      new CoreTypes(sdk),
    );
    new FastaTypesTest(hierarchy, environment).run();
  }

  asyncTest(() => context.runInContext<void>(doIt));
}

class FastaTypesTest extends SubtypeTest<DartType, TypeParserEnvironment> {
  final ClassHierarchyBuilder hierarchy;

  final TypeParserEnvironment environment;

  FastaTypesTest(this.hierarchy, this.environment);

  @override
  DartType toType(String text, TypeParserEnvironment environment) {
    return environment.parseType(text);
  }

  @override
  IsSubtypeOf isSubtypeImpl(DartType subtype, DartType supertype) {
    return hierarchy.types.performSubtypeCheck(subtype, supertype);
  }

  @override
  TypeParserEnvironment extend({
    String? typeParameters,
    String? functionTypeTypeParameters,
  }) {
    return environment
        .extendWithTypeParameters(typeParameters)
        .extendWithStructuralParameters(functionTypeTypeParameters);
  }
}
