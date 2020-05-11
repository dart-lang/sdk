// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert" show json, utf8;

import "dart:io" show File, gzip;

import "package:kernel/ast.dart" show Component, DartType, Library;

import "package:kernel/class_hierarchy.dart" show ClassHierarchy;

import "package:kernel/core_types.dart" show CoreTypes;

import "package:kernel/target/targets.dart" show NoneTarget, TargetFlags;

import 'package:kernel/testing/type_parser_environment.dart'
    show TypeParserEnvironment, parseLibrary;

import "package:kernel/type_environment.dart"
    show SubtypeCheckMode, TypeEnvironment;

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
  TypeParserEnvironment environment = new TypeParserEnvironment(uri, uri);
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
    TypeParserEnvironment localEnvironment = environment;
    if (arguments.length > 2) {
      List<Object> typeParametersSource = arguments[2];
      localEnvironment = environment
          .extendWithTypeParameters("${typeParametersSource.join(', ')}");
    }
    DartType s = localEnvironment.parseType(sSource);
    DartType t = localEnvironment.parseType(tSource);
    subtypeChecks.add(new SubtypeCheck(s, t, kind == "isSubtype"));
  }
  return new SubtypesBenchmark(library, subtypeChecks);
}

void performChecks(List<SubtypeCheck> checks, TypeEnvironment environment) {
  for (int i = 0; i < checks.length; i++) {
    SubtypeCheck check = checks[i];
    bool isSubtype = environment.isSubtypeOf(
        check.s, check.t, SubtypeCheckMode.ignoringNullabilities);
    if (isSubtype != check.isSubtype) {
      throw "Check failed: $check";
    }
  }
}

void performFastaChecks(
    List<SubtypeCheck> checks, ClassHierarchyBuilder hierarchy) {
  for (int i = 0; i < checks.length; i++) {
    SubtypeCheck check = checks[i];
    bool isSubtype = hierarchy.types
        .isSubtypeOf(check.s, check.t, SubtypeCheckMode.ignoringNullabilities);
    if (isSubtype != check.isSubtype) {
      throw "Check failed: $check";
    }
  }
}

Future<void> run(Uri benchmarkInput, String name) async {
  const int runs = 50;
  final Ticker ticker = new Ticker(isVerbose: false);
  Stopwatch kernelWatch = new Stopwatch();
  Stopwatch fastaWatch = new Stopwatch();
  List<int> bytes = await new File.fromUri(benchmarkInput).readAsBytes();
  if (bytes.length > 3) {
    if (bytes[0] == 0x1f && bytes[1] == 0x8b && bytes[2] == 0x08) {
      bytes = gzip.decode(bytes);
    }
  }
  SubtypesBenchmark bench = parseBenchMark(utf8.decode(bytes));
  bytes = null;
  ticker.logMs("Parsed benchmark file");
  Component c = new Component(libraries: [bench.library]);
  CoreTypes coreTypes = new CoreTypes(c);
  ClassHierarchy hierarchy = new ClassHierarchy(c, coreTypes);
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
    ClassBuilder objectClass =
        loader.coreLibrary.lookupLocalMember("Object", required: true);
    ClassHierarchyBuilder hierarchy =
        new ClassHierarchyBuilder(objectClass, loader, coreTypes);

    for (int i = 0; i < runs; i++) {
      kernelWatch.start();
      performChecks(bench.checks, environment);
      kernelWatch.stop();

      fastaWatch.start();
      performFastaChecks(bench.checks, hierarchy);
      fastaWatch.stop();

      if (i == 0) {
        print("SubtypeKernel${name}First(RuntimeRaw): "
            "${kernelWatch.elapsedMilliseconds} ms");
        print("SubtypeFasta${name}First(RuntimeRaw): "
            "${fastaWatch.elapsedMilliseconds} ms");
      }
    }
  });

  print("SubtypeKernel${name}Avg${runs}(RuntimeRaw): "
      "${kernelWatch.elapsedMilliseconds / runs} ms");
  print("SubtypeFasta${name}Avg${runs}(RuntimeRaw): "
      "${fastaWatch.elapsedMilliseconds / runs} ms");
}

main() => run(Uri.base.resolve("type_checks.json"), "***");
