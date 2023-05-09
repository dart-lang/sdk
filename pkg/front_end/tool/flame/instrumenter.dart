// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:_fe_analyzer_shared/src/util/options.dart';
import 'package:front_end/src/base/processed_options.dart';

import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/kernel.dart';

import '../_fasta/additional_targets.dart';
import '../_fasta/command_line.dart';
import '../_fasta/compile.dart' as fasta_compile;

/// Instrumenter that can produce flame graphs, count invocations,
/// perform time tracking etc.
///
/// ### Example of using this to produce data for a flame graph
///
/// ```
/// out/ReleaseX64/dart pkg/front_end/tool/flame/instrumenter.dart pkg/front_end/tool/_fasta/compile.dart
/// out/ReleaseX64/dart pkg/front_end/tool/_fasta/compile.dart.dill.instrumented.dill --omit-platform pkg/front_end/tool/_fasta/compile.dart
/// out/ReleaseX64/dart pkg/front_end/tool/flame/instrumenter.dart pkg/front_end/tool/_fasta/compile.dart --candidates=cfe_compile_trace_candidates.txt
/// out/ReleaseX64/dart pkg/front_end/tool/_fasta/compile.dart.dill.instrumented.dill --omit-platform pkg/front_end/tool/_fasta/compile.dart
/// out/ReleaseX64/dart pkg/front_end/tool/flame/instrumenter.dart pkg/front_end/tool/_fasta/compile.dart --candidates=cfe_compile_trace_candidates_subsequent.txt
/// out/ReleaseX64/dart pkg/front_end/tool/_fasta/compile.dart.dill.instrumented.dill --omit-platform pkg/front_end/tool/_fasta/compile.dart
/// ```
///
/// Where it's instrumented in several passes to automatically find the
/// "interesting" procedures to instrument which gives a good overview without
/// costing too much (and thereby still display ~correct timings).
///
/// This produces a file "cfe_compile_trace.txt" that can be displayed via
/// Chromes about://tracing tool.
///
///
/// ### Example of using this to count method calls
///
/// ```
/// out/ReleaseX64/dart pkg/front_end/tool/flame/instrumenter.dart pkg/front_end/tool/_fasta/compile.dart --count
/// out/ReleaseX64/dart pkg/front_end/tool/_fasta/compile.dart.dill.instrumented.dill pkg/front_end/tool/_fasta/compile.dart
/// ```
///
/// It will produce an output like this:
/// ```
/// [...]
///  4,597,852: utf8_bytes_scanner.dart|Utf8BytesScanner.stringOffset
///  4,775,443: ast_to_binary.dart|BinaryPrinter.writeUInt30
///  5,213,581: token.dart|SimpleToken.kind
///  5,299,735: ast_to_binary.dart|BufferedSink.addByte
///  8,253,178: abstract_scanner.dart|_isIdentifierChar
/// 11,853,919: util.dart|optional
/// 12,889,502: token.dart|SimpleToken.stringValue
/// 20,468,609: token.dart|SimpleToken.type
/// 20,749,114: utf8_bytes_scanner.dart|Utf8BytesScanner.advance
/// ```
///
/// ### Example of using this to get combined time on stack
///
/// ```
/// out/ReleaseX64/dart pkg/front_end/tool/flame/instrumenter.dart -Diterations=10 pkg/front_end/tool/_fasta/compile.dart --single-timer "--candidates-raw=flow_analysis.dart|*"
/// out/ReleaseX64/dart pkg/front_end/tool/_fasta/compile.dart.dill.instrumented.dill pkg/front_end/tool/_fasta/compile.dart
/// ```
///
/// This will give a combined runtime of when any of the instrumented procedures
/// was on the stack. In the example note how `-Diterations=10` will be passed
/// to the compilation, but that the "candidates" (i.e. the data to instrument)
/// is given directly via `"--candidates-raw=flow_analysis.dart|*"` and uses the
/// `*` as a wildcard meaning everything in this file.
///
/// It will produce an output like this:
/// ```
/// Runtime: 3834491044
/// Runtime in seconds: 3.834491044
/// Visits: 52643690
/// Active: 0
/// Stopwatch frequency: 1000000000
/// ```
///
/// ### Example of using this to get timings for when on stack:
///
/// ```
/// out/ReleaseX64/dart --enable-asserts pkg/front_end/tool/flame/instrumenter.dart -Diterations=10 pkg/front_end/tool/_fasta/compile.dart --timer "--candidates-raw=flow_analysis.dart|*"
/// out/ReleaseX64/dart pkg/front_end/tool/_fasta/compile.dart.dill.instrumented.dill pkg/front_end/tool/_fasta/compile.dart
/// ```
///
/// This will give runtime info for all instrumented procedures, timing when
/// they're on the stack.
/// Note in the example output below for instance `_FlowAnalysisImpl._merge`
/// just passes to `FlowModel.merge`, so while the "self time" of the first is
/// almost nothing it's actually on the stack (slightly) longer.
///
/// This will produce output like this:
/// ```
/// [...]
/// flow_analysis.dart|_FlowAnalysisImpl.propertyGet: runtime: 818095151 (0.818095151 s), visits: 1328320, active: 0
/// flow_analysis.dart|FlowModel._updateVariableInfo: runtime: 827669322 (0.827669322 s), visits: 968180, active: 0
/// flow_analysis.dart|_FlowAnalysisImpl.variableRead: runtime: 1012755488 (1.012755488 s), visits: 1100140, active: 0
/// flow_analysis.dart|FlowModel.joinVariableInfo: runtime: 1118758076 (1.118758076 s), visits: 320810, active: 0
/// flow_analysis.dart|FlowModel.merge: runtime: 1185477853 (1.185477853 s), visits: 334100, active: 0
/// flow_analysis.dart|_FlowAnalysisImpl._merge: runtime: 1238735352 (1.238735352 s), visits: 334100, active: 0
/// ```
Future<void> main(List<String> arguments) async {
  Directory tmpDir = Directory.systemTemp.createTempSync("cfe_instrumenter");
  try {
    await _main(arguments, tmpDir);
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}

Future<void> _main(List<String> inputArguments, Directory tmpDir) async {
  List<String> candidates = [];
  List<String> candidatesRaw = [];
  List<String> arguments = [];
  bool doCount = false;
  bool doTimer = false;
  bool doSingleTimer = false;
  for (String arg in inputArguments) {
    if (arg == "--count") {
      doCount = true;
    } else if (arg == "--timer") {
      doTimer = true;
    } else if (arg == "--single-timer") {
      doSingleTimer = true;
    } else if (arg.startsWith("--candidates=")) {
      candidates.add(arg.substring("--candidates=".length));
    } else if (arg.startsWith("--candidates-raw=")) {
      candidatesRaw.add(arg.substring("--candidates-raw=".length));
    } else {
      arguments.add(arg);
    }
  }
  bool reportCandidates = candidates.isEmpty && candidatesRaw.isEmpty;
  setupWantedMap(candidates, candidatesRaw);

  installAdditionalTargets();
  ParsedOptions parsedOptions =
      ParsedOptions.parse(arguments, optionSpecification);
  ProcessedOptions options = analyzeCommandLine("compile", parsedOptions, true);
  Uri? output = options.output;
  if (output == null) throw "No output";
  if (!output.isScheme("file")) throw "Output won't be saved";

  print("Compiling the instrumentation library.");
  Uri instrumentationLibDill = tmpDir.uri.resolve("instrumenter.dill");
  String libFilename = "instrumenter_lib.dart";
  if (doCount) {
    libFilename = "instrumenter_lib_counter.dart";
  } else if (doTimer) {
    libFilename = "instrumenter_lib_timer.dart";
  } else if (doSingleTimer) {
    libFilename = "instrumenter_lib_single_timer.dart";
  }
  await fasta_compile.main([
    "--omit-platform",
    "-o=${instrumentationLibDill.toFilePath()}",
    Platform.script.resolve(libFilename).toFilePath()
  ]);
  if (!File.fromUri(instrumentationLibDill).existsSync()) {
    throw "Instrumentation library didn't compile as expected.";
  }

  print("Compiling the given input.");
  await fasta_compile.main(arguments);

  print("Reading the compiled dill.");
  Component component = new Component();
  List<int> bytes = new File.fromUri(output).readAsBytesSync();
  new BinaryBuilder(bytes).readComponent(component);

  List<Procedure> procedures = [];
  List<Constructor> constructors = [];
  for (Library lib in component.libraries) {
    if (lib.importUri.scheme == "dart") continue;
    for (Class c in lib.classes) {
      addIfWantedProcedures(procedures, c.procedures,
          includeAll: reportCandidates);
      if (!reportCandidates || doCount || doTimer || doSingleTimer) {
        addIfWantedConstructors(constructors, c.constructors,
            includeAll: reportCandidates);
      }
    }
    addIfWantedProcedures(procedures, lib.procedures,
        includeAll: reportCandidates);
  }
  print("Procedures: ${procedures.length}");
  print("Constructors: ${constructors.length}");

  bytes = File.fromUri(instrumentationLibDill).readAsBytesSync();
  new BinaryBuilder(bytes).readComponent(component);

  // TODO: Check that this is true.
  Library instrumenterLib = component.libraries.last;
  Procedure instrumenterInitialize =
      instrumenterLib.procedures.firstWhere((p) => p.name.text == "initialize");
  Procedure instrumenterEnter =
      instrumenterLib.procedures.firstWhere((p) => p.name.text == "enter");
  Procedure instrumenterExit =
      instrumenterLib.procedures.firstWhere((p) => p.name.text == "exit");
  Procedure instrumenterReport =
      instrumenterLib.procedures.firstWhere((p) => p.name.text == "report");

  int id = 0;
  for (Procedure p in procedures) {
    int thisId = id++;
    wrapProcedure(p, thisId, instrumenterEnter, instrumenterExit);
  }
  for (Constructor c in constructors) {
    int thisId = id++;
    wrapConstructor(c, thisId, instrumenterEnter, instrumenterExit);
  }

  initializeAndReport(component.mainMethod!, instrumenterInitialize, procedures,
      constructors, instrumenterReport, reportCandidates);

  print("Writing output.");
  String outString = output.toFilePath() + ".instrumented.dill";
  await writeComponentToBinary(component, outString);
  print("Wrote to $outString");
}

void addIfWantedProcedures(List<Procedure> output, List<Procedure> input,
    {required bool includeAll}) {
  for (Procedure p in input) {
    if (p.function.body == null) continue;
    // Yielding functions doesn't work well with the begin/end scheme.
    if (p.function.dartAsyncMarker == AsyncMarker.SyncStar) continue;
    if (p.function.dartAsyncMarker == AsyncMarker.AsyncStar) continue;
    if (!includeAll) {
      String name = getProcedureName(p);
      Set<String> procedureNamesWantedInFile =
          wanted[p.fileUri.pathSegments.last] ?? const {};
      if (!procedureNamesWantedInFile.contains(name) &&
          !procedureNamesWantedInFile.contains("*")) {
        continue;
      }
    }
    output.add(p);
  }
}

void addIfWantedConstructors(List<Constructor> output, List<Constructor> input,
    {required bool includeAll}) {
  for (Constructor c in input) {
    if (c.isExternal) continue;
    if (!includeAll) {
      String name = getConstructorName(c);
      Set<String> constructorNamesWantedInFile =
          wanted[c.fileUri.pathSegments.last] ?? const {};
      if (!constructorNamesWantedInFile.contains(name) &&
          !constructorNamesWantedInFile.contains("*")) {
        continue;
      }
    }
    output.add(c);
  }
}

String getProcedureName(Procedure p) {
  String name = p.name.text;
  if (p.isSetter) {
    name = "set:$name";
  }
  if (p.parent is Class) {
    return "${(p.parent as Class).name}.$name";
  } else {
    return name;
  }
}

String getConstructorName(Constructor c) {
  String name = "constructor:${c.name.text}";
  Class parent = c.parent as Class;
  return "${parent.name}.$name";
}

void setupWantedMap(List<String> candidates, List<String> candidatesRaw) {
  for (String filename in candidates) {
    File f = new File(filename);
    if (!f.existsSync()) throw "$filename doesn't exist.";
    for (String line in f.readAsLinesSync()) {
      int index = line.indexOf("|");
      if (index < 0) throw "Not correctly formatted: $line (from $filename)";
      String file = line.substring(0, index);
      String displayName = line.substring(index + 1);
      Set<String> existingInFile = wanted[file] ??= {};
      existingInFile.add(displayName);
    }
  }
  for (String raw in candidatesRaw) {
    for (String line in raw.split(",")) {
      int index = line.indexOf("|");
      if (index < 0) throw "Not correctly formatted: $line ($raw)";
      String file = line.substring(0, index);
      String displayName = line.substring(index + 1);
      Set<String> existingInFile = wanted[file] ??= {};
      existingInFile.add(displayName);
    }
  }
}

Map<String, Set<String>> wanted = {};

void initializeAndReport(
    Procedure mainProcedure,
    Procedure initializeProcedure,
    List<Procedure> procedures,
    List<Constructor> constructors,
    Procedure instrumenterReport,
    bool reportCandidates) {
  Block block = new Block([
    new ExpressionStatement(new StaticInvocation(
        initializeProcedure,
        new Arguments([
          new IntLiteral(procedures.length + constructors.length),
          new BoolLiteral(reportCandidates),
        ]))),
    new TryFinally(
        mainProcedure.function.body as Statement,
        new ExpressionStatement(new StaticInvocation(
            instrumenterReport,
            new Arguments([
              new ListLiteral([
                ...procedures.map(
                    (p) => new StringLiteral("${p.fileUri.pathSegments.last}|"
                        "${getProcedureName(p)}")),
                ...constructors.map(
                    (c) => new StringLiteral("${c.fileUri.pathSegments.last}|"
                        "${getConstructorName(c)}")),
              ]),
            ])))),
  ]);
  mainProcedure.function.body = block;
  block.parent = mainProcedure.function;
}

void wrapProcedure(Procedure p, int id, Procedure instrumenterEnter,
    Procedure instrumenterExit) {
  Block block = new Block([
    new ExpressionStatement(new StaticInvocation(
        instrumenterEnter, new Arguments([new IntLiteral(id)]))),
    p.function.body as Statement
  ]);
  TryFinally tryFinally = new TryFinally(
      block,
      new ExpressionStatement(new StaticInvocation(
          instrumenterExit, new Arguments([new IntLiteral(id)]))));
  p.function.body = tryFinally;
  tryFinally.parent = p.function;
}

void wrapConstructor(Constructor c, int id, Procedure instrumenterEnter,
    Procedure instrumenterExit) {
  if (c.function.body == null || c.function.body is EmptyStatement) {
    // We just completely replace the body.
    Block block = new Block([
      new ExpressionStatement(new StaticInvocation(
          instrumenterEnter, new Arguments([new IntLiteral(id)]))),
      new ExpressionStatement(new StaticInvocation(
          instrumenterExit, new Arguments([new IntLiteral(id)]))),
    ]);
    c.function.body = block;
    block.parent = c.function;
    return;
  }

  // We retain the original body as with procedures.
  Block block = new Block([
    new ExpressionStatement(new StaticInvocation(
        instrumenterEnter, new Arguments([new IntLiteral(id)]))),
    c.function.body as Statement,
  ]);
  TryFinally tryFinally = new TryFinally(
      block,
      new ExpressionStatement(new StaticInvocation(
          instrumenterExit, new Arguments([new IntLiteral(id)]))));
  c.function.body = tryFinally;
  tryFinally.parent = c.function;
}
