// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert" show json;

import "dart:io" show File;

import "package:kernel/ast.dart" show Component, DartType, Library;

import "package:kernel/class_hierarchy.dart" show ClassHierarchy;

import "package:kernel/core_types.dart" show CoreTypes;

import "package:kernel/target/targets.dart" show NoneTarget, TargetFlags;

import "package:kernel/type_environment.dart" show TypeEnvironment;

import "kernel_type_parser.dart"
    show KernelEnvironment, KernelFromParsedType, parseLibrary;

import "type_parser.dart" as type_parser show parse, parseTypeVariables;

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

class SubtypesBenchmark {
  final Library library;
  final List<SubtypeCheck> checks;

  SubtypesBenchmark(this.library, this.checks);
}

class SubtypeCheck {
  final DartType s;
  final DartType t;
  final bool isSubtype;

  SubtypeCheck(this.s, this.t, this.isSubtype);

  String toString() {
    return (new StringBuffer()
          ..write(s)
          ..write(isSubtype ? " <: " : " !<: ")
          ..write(t))
        .toString();
  }
}

SubtypesBenchmark parseBenchMark(String source) {
  Map<Object, Object> data = json.decode(source);
  List<Object> classes = data["classes"];
  Uri uri = Uri.parse("dart:core");
  KernelEnvironment environment = new KernelEnvironment(uri, uri);
  Library library =
      parseLibrary(uri, classes.join("\n"), environment: environment);
  List<Object> checks = data["checks"];
  List<SubtypeCheck> subtypeChecks = <SubtypeCheck>[];
  for (Map<Object, Object> check in checks) {
    String kind = check["kind"];
    List<Object> arguments = check["arguments"];
    String sSource = arguments[0];
    String tSource = arguments[1];
    if (sSource.contains("?")) continue;
    if (tSource.contains("?")) continue;
    if (sSource.contains("⊥")) continue;
    if (tSource.contains("⊥")) continue;
    KernelEnvironment localEnvironment = environment;
    if (arguments.length > 2) {
      List<Object> typeParametersSource = arguments[2];
      localEnvironment = const KernelFromParsedType()
          .computeTypeParameterEnvironment(
              type_parser
                  .parseTypeVariables("<${typeParametersSource.join(', ')}>"),
              environment)
          .environment;
    }
    DartType s = localEnvironment
        .kernelFromParsedType(type_parser.parse(sSource).single);
    DartType t = localEnvironment
        .kernelFromParsedType(type_parser.parse(tSource).single);
    subtypeChecks.add(new SubtypeCheck(s, t, kind == "isSubtype"));
  }
  return new SubtypesBenchmark(library, subtypeChecks);
}

void performChecks(List<SubtypeCheck> checks, TypeEnvironment environment) {
  for (int i = 0; i < checks.length; i++) {
    SubtypeCheck check = checks[i];
    bool isSubtype = environment.isSubtypeOf(check.s, check.t);
    if (isSubtype != check.isSubtype) {
      throw "Check failed: $check";
    }
  }
}

void performFastaChecks(
    List<SubtypeCheck> checks, ClassHierarchyBuilder hierarchy) {
  for (int i = 0; i < checks.length; i++) {
    SubtypeCheck check = checks[i];
    bool isSubtype = hierarchy.types.isSubtypeOfKernel(check.s, check.t);
    if (isSubtype != check.isSubtype) {
      throw "Check failed: $check";
    }
  }
}

main() async {
  const int runs = 50;
  final Ticker ticker = new Ticker(isVerbose: true);
  Stopwatch kernelWatch = new Stopwatch();
  Stopwatch fastaWatch = new Stopwatch();
  SubtypesBenchmark bench =
      parseBenchMark(await new File("type_checks.json").readAsString());
  ticker.logMs("Parsed benchmark file");
  Component c = new Component(libraries: [bench.library]);
  ClassHierarchy hierarchy = new ClassHierarchy(c);
  CoreTypes coreTypes = new CoreTypes(c);
  TypeEnvironment environment = new TypeEnvironment(coreTypes, hierarchy);

  final CompilerContext context = new CompilerContext(new ProcessedOptions(
      options: new CompilerOptions()
        ..packagesFileUri = Uri.base.resolve(".packages")));
  await context.runInContext<void>((_) async {
    DillTarget target = new DillTarget(
        ticker,
        await context.options.getUriTranslator(),
        new NoneTarget(new TargetFlags()));
    final DillLoader loader = target.loader;
    loader.appendLibraries(c);
    await target.buildOutlines();
    KernelClassBuilder objectClass = loader.coreLibrary["Object"];
    ClassHierarchyBuilder hierarchy =
        new ClassHierarchyBuilder(objectClass, loader, coreTypes);

    for (int i = 0; i < runs; i++) {
      kernelWatch.start();
      performChecks(bench.checks, environment);
      kernelWatch.stop();

      fastaWatch.start();
      performFastaChecks(bench.checks, hierarchy);
      fastaWatch.stop();
    }
  });

  print(
      "Kernel average over $runs runs (${bench.checks.length} type tests per run):"
      " ${kernelWatch.elapsedMilliseconds / runs}ms");
  print(
      "Fasta average over $runs runs (${bench.checks.length} type tests per run):"
      " ${fastaWatch.elapsedMilliseconds / runs}ms");
}
