// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/util/options.dart';
import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:front_end/src/base/file_system_dependency_tracker.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/kernel.dart';

import '../additional_targets.dart';
import '../command_line.dart';
import '../compile.dart' as cfe_compile;

import 'instrumenter.dart' as self;

/// Instrumenter that can produce flame graphs, count invocations,
/// perform time tracking etc.
///
/// ### Example of using this to produce data for a flame graph
///
/// ```
/// out/ReleaseX64/dart pkg/front_end/tool/flame/instrumenter.dart pkg/front_end/tool/compile.dart
/// out/ReleaseX64/dart pkg/front_end/tool/compile.dart.dill.instrumented.dill --omit-platform pkg/front_end/tool/compile.dart
/// out/ReleaseX64/dart pkg/front_end/tool/flame/instrumenter.dart pkg/front_end/tool/compile.dart --candidates=cfe_compile_trace_candidates.txt
/// out/ReleaseX64/dart pkg/front_end/tool/compile.dart.dill.instrumented.dill --omit-platform pkg/front_end/tool/compile.dart
/// out/ReleaseX64/dart pkg/front_end/tool/flame/instrumenter.dart pkg/front_end/tool/compile.dart --candidates=cfe_compile_trace_candidates_subsequent.txt
/// out/ReleaseX64/dart pkg/front_end/tool/compile.dart.dill.instrumented.dill --omit-platform pkg/front_end/tool/compile.dart
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
/// out/ReleaseX64/dart pkg/front_end/tool/flame/instrumenter.dart pkg/front_end/tool/compile.dart --count
/// out/ReleaseX64/dart pkg/front_end/tool/compile.dart.dill.instrumented.dill pkg/front_end/tool/compile.dart
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
/// out/ReleaseX64/dart pkg/front_end/tool/flame/instrumenter.dart -Diterations=10 pkg/front_end/tool/compile.dart --single-timer "--candidates-raw=flow_analysis.dart|*"
/// out/ReleaseX64/dart pkg/front_end/tool/compile.dart.dill.instrumented.dill pkg/front_end/tool/compile.dart
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
/// out/ReleaseX64/dart --enable-asserts pkg/front_end/tool/flame/instrumenter.dart -Diterations=10 pkg/front_end/tool/compile.dart --timer "--candidates-raw=flow_analysis.dart|*"
/// out/ReleaseX64/dart pkg/front_end/tool/compile.dart.dill.instrumented.dill pkg/front_end/tool/compile.dart
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
    await mainHelper(arguments, tmpDir);
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}

Future<Component> mainHelper(
  List<String> inputArguments,
  Directory tmpDir,
) async {
  List<String> candidates = [];
  List<String> candidatesRaw = [];
  List<String> arguments = [];
  Set<String>? onlyIfIncludingCertainCalls;
  int numTools = 0;
  bool doCount = false;
  bool doCountCalls = false;
  bool doTimer = false;
  bool doSingleTimer = false;
  bool omitPlatform = false;
  bool delete = false;
  for (String arg in inputArguments) {
    if (arg == "--count") {
      doCount = true;
      numTools++;
    } else if (arg == "--countCalls") {
      doCountCalls = true;
      numTools++;
    } else if (arg == "--onlySome") {
      onlyIfIncludingCertainCalls = const {
        "any",
        "every",
        "firstWhere",
        "firstWhereOrNull",
        "fold",
        "followedBy",
        "lastWhere",
        "lastWhereOrNull",
        "map",
        "reduce",
        "singleWhere",
        "singleWhereOrNull",
        "whereType",
      };
    } else if (arg.startsWith("--onlySome=")) {
      onlyIfIncludingCertainCalls = arg
          .substring("--onlySome=".length)
          .split(",")
          .toSet();
    } else if (arg == "--timer") {
      doTimer = true;
      numTools++;
    } else if (arg == "--single-timer") {
      doSingleTimer = true;
      numTools++;
    } else if (arg.startsWith("--candidates=")) {
      candidates.add(arg.substring("--candidates=".length));
    } else if (arg.startsWith("--candidates-raw=")) {
      candidatesRaw.add(arg.substring("--candidates-raw=".length));
    } else if (arg == "--omit-platform") {
      omitPlatform = true;
    } else if (arg == "--delete") {
      delete = true;
    } else {
      arguments.add(arg);
    }
  }
  if (numTools != 1) {
    throw "Need exactly one tool "
        "(--count, --countCalls, --timer or --single-timer)";
  }
  if (doCountCalls &&
      (onlyIfIncludingCertainCalls == null ||
          onlyIfIncludingCertainCalls.isEmpty)) {
    throw "--countCalls needs calls to wrap via "
        "--onlySome or --onlySome=<f1>,<f2> etc";
  }
  bool reportCandidates = candidates.isEmpty && candidatesRaw.isEmpty;

  installAdditionalTargets();

  Uri output = parseCompilerArguments(arguments);

  Map<String, Set<String>> wanted = setupWantedMap(candidates, candidatesRaw);

  String libFilename = "instrumenter_lib.dart";
  if (doCount || doCountCalls) {
    libFilename = "instrumenter_lib_counter.dart";
  } else if (doTimer) {
    libFilename = "instrumenter_lib_timer.dart";
  } else if (doSingleTimer) {
    libFilename = "instrumenter_lib_single_timer.dart";
  }

  InstrumenterConfig config;
  if (doCountCalls) {
    config = new CountCalls(
      libFilename: libFilename,
      reportCandidates: reportCandidates,
      wanted: wanted,
      includeAll: reportCandidates,
      includeConstructors: true,
      onlyIfIncludingCertainCalls: onlyIfIncludingCertainCalls!,
    );
  } else {
    config = new TimerCounterInstrumenterConfig(
      libFilename: libFilename,
      reportCandidates: reportCandidates,
      wanted: wanted,
      includeAll: reportCandidates,
      includeConstructors:
          !reportCandidates || doCount || doTimer || doSingleTimer,
      onlyIfIncludingCertainCalls: onlyIfIncludingCertainCalls,
    );
  }
  Component component = await compileInstrumentationLibrary(
    tmpDir,
    config,
    arguments,
    output,
    omitPlatform: omitPlatform,
  );

  if (delete) {
    File.fromUri(output).deleteSync();
  } else {
    print("Writing output.");
    String outString = output.toFilePath() + ".instrumented.dill";
    await writeComponentToBinary(component, outString);
    print("Wrote to $outString");
  }

  return component;
}

Uri parseCompilerArguments(List<String> arguments) {
  installAdditionalTargets();
  FileSystemDependencyTracker tracker = new FileSystemDependencyTracker();
  ParsedOptions parsedOptions = ParsedOptions.parse(
    arguments,
    optionSpecification,
  );
  ProcessedOptions options = analyzeCommandLine(
    tracker,
    "compile",
    parsedOptions,
    true,
  );
  Uri? output = options.output;
  if (output == null) throw "No output";
  if (!output.isScheme("file")) throw "Output won't be saved";
  return output;
}

abstract interface class InstrumenterConfig {
  String get libFilename;
  String get beforeName;
  String get enterName;
  String get exitName;
  String get afterName;

  void wrapProcedure(
    Procedure p,
    List<String> namesById,
    Procedure instrumenterEnter,
    Procedure instrumenterExit,
  );

  void wrapConstructor(
    Constructor c,
    List<String> namesById,
    Procedure instrumenterEnter,
    Procedure instrumenterExit,
  );

  bool includeProcedure(Procedure procedure);
  bool includeConstructor(Constructor constructor);

  Arguments createBeforeArguments(List<String> namesById);

  Arguments createAfterArguments(List<String> namesById);

  Arguments createEnterArguments(int id, Member member);

  Arguments createExitArguments(int id, Member member);
}

class TimerCounterInstrumenterConfig implements InstrumenterConfig {
  @override
  final String libFilename;
  final bool reportCandidates;
  final bool includeAll;
  final bool includeConstructors;
  final Map<String, Set<String>> wanted;
  final Set<String>? onlyIfIncludingCertainCalls;

  TimerCounterInstrumenterConfig({
    required this.libFilename,
    required this.reportCandidates,
    required this.includeAll,
    required this.includeConstructors,
    required this.wanted,
    required this.onlyIfIncludingCertainCalls,
  });

  @override
  void wrapConstructor(
    Constructor c,
    List<String> namesById,
    Procedure instrumenterEnter,
    Procedure instrumenterExit,
  ) {
    self.wrapConstructor(
      this,
      c,
      namesById,
      instrumenterEnter,
      instrumenterExit,
    );
  }

  @override
  void wrapProcedure(
    Procedure p,
    List<String> namesById,
    Procedure instrumenterEnter,
    Procedure instrumenterExit,
  ) {
    self.wrapProcedure(this, p, namesById, instrumenterEnter, instrumenterExit);
  }

  @override
  String get beforeName => 'initialize';

  @override
  String get enterName => 'enter';

  @override
  String get exitName => 'exit';

  @override
  String get afterName => 'report';

  @override
  bool includeProcedure(Procedure p) {
    if (onlyIfIncludingCertainCalls != null) {
      return _memberCallsCertainThings(p);
    }
    if (includeAll) return true;
    String name = getProcedureName(p);
    Set<String> procedureNamesWantedInFile =
        wanted[p.fileUri.pathSegments.last] ?? const {};
    return procedureNamesWantedInFile.contains(name) ||
        procedureNamesWantedInFile.contains("*");
  }

  @override
  bool includeConstructor(Constructor c) {
    if (!includeConstructors) return false;
    if (onlyIfIncludingCertainCalls != null) {
      return _memberCallsCertainThings(c);
    }
    if (includeAll) return true;
    String name = getConstructorName(c);
    Set<String> constructorNamesWantedInFile =
        wanted[c.fileUri.pathSegments.last] ?? const {};
    return constructorNamesWantedInFile.contains(name) ||
        constructorNamesWantedInFile.contains("*");
  }

  @override
  Arguments createBeforeArguments(List<String> namesById) {
    return new Arguments([
      new IntLiteral(namesById.length),
      new BoolLiteral(reportCandidates),
    ]);
  }

  @override
  Arguments createAfterArguments(List<String> namesById) {
    return new Arguments([
      new ListLiteral(
        List.generate(
          namesById.length,
          (i) => new StringLiteral(namesById[i]),
          growable: false,
        ),
      ),
    ]);
  }

  @override
  Arguments createEnterArguments(int id, Member member) {
    return new Arguments([new IntLiteral(id)]);
  }

  @override
  Arguments createExitArguments(int id, Member member) {
    return new Arguments([new IntLiteral(id)]);
  }

  bool _memberCallsCertainThings(Member m) {
    return _CollectCallsVisitor.collectCalls(
      m.function?.body,
    ).intersection(onlyIfIncludingCertainCalls!).isNotEmpty;
  }
}

class CountCalls extends TimerCounterInstrumenterConfig {
  CountCalls({
    required super.libFilename,
    required super.reportCandidates,
    required super.includeAll,
    required super.includeConstructors,
    required super.wanted,
    required Set<String> super.onlyIfIncludingCertainCalls,
  });

  @override
  void wrapConstructor(
    Constructor c,
    List<String> namesById,
    Procedure instrumenterEnter,
    Procedure instrumenterExit,
  ) {
    _InvocationWrapperTransformer.wrap(
      this,
      c,
      onlyIfIncludingCertainCalls!,
      namesById,
      instrumenterEnter,
    );
  }

  @override
  void wrapProcedure(
    Procedure p,
    List<String> namesById,
    Procedure instrumenterEnter,
    Procedure instrumenterExit,
  ) {
    _InvocationWrapperTransformer.wrap(
      this,
      p,
      onlyIfIncludingCertainCalls!,
      namesById,
      instrumenterEnter,
    );
  }
}

Future<Component> compileInstrumentationLibrary(
  Directory tmpDir,
  InstrumenterConfig config,
  List<String> arguments,
  Uri output, {
  bool omitPlatform = false,
}) async {
  print("Compiling the instrumentation library.");
  Uri instrumentationLibDill = tmpDir.uri.resolve("instrumenter.dill");
  await cfe_compile.main([
    "--omit-platform",
    "-o=${instrumentationLibDill.toFilePath()}",
    Platform.script.resolve(config.libFilename).toFilePath(),
  ]);
  if (!File.fromUri(instrumentationLibDill).existsSync()) {
    throw "Instrumentation library didn't compile as expected.";
  }

  print("Compiling the given input.");
  await cfe_compile.main(arguments);

  print("Reading the compiled dill.");
  Component component = new Component();
  Uint8List bytes = new File.fromUri(output).readAsBytesSync();
  new BinaryBuilder(bytes).readComponent(component);

  int librariesBefore = component.libraries.length;

  bytes = File.fromUri(instrumentationLibDill).readAsBytesSync();
  new BinaryBuilder(bytes).readComponent(component);

  assert(librariesBefore + 1 == component.libraries.length);

  List<Procedure> procedures = [];
  List<Constructor> constructors = [];
  for (int i = 0; i < librariesBefore; i++) {
    Library lib = component.libraries[i];
    if (lib.importUri.scheme == "dart") continue;
    for (Class c in lib.classes) {
      addIfWantedProcedures(config, procedures, c.procedures);
      addIfWantedConstructors(config, constructors, c.constructors);
    }
    addIfWantedProcedures(config, procedures, lib.procedures);
  }
  print("Procedures: ${procedures.length}");
  print("Constructors: ${constructors.length}");

  // TODO: Check that this is true.
  Library instrumenterLib = component.libraries.singleWhere(
    (lib) => lib.fileUri.path.endsWith(config.libFilename),
  );
  Procedure instrumenterInitialize = instrumenterLib.procedures.singleWhere(
    (p) => p.name.text == config.beforeName,
  );
  Procedure instrumenterEnter = instrumenterLib.procedures.singleWhere(
    (p) => p.name.text == config.enterName,
  );
  Procedure instrumenterExit = instrumenterLib.procedures.singleWhere(
    (p) => p.name.text == config.exitName,
  );
  Procedure instrumenterReport = instrumenterLib.procedures.singleWhere(
    (p) => p.name.text == config.afterName,
  );

  List<String> namesById = [];
  for (Procedure p in procedures) {
    config.wrapProcedure(p, namesById, instrumenterEnter, instrumenterExit);
  }
  for (Constructor c in constructors) {
    config.wrapConstructor(c, namesById, instrumenterEnter, instrumenterExit);
  }

  initializeAndReport(
    config,
    component.mainMethod!,
    instrumenterInitialize,
    namesById,
    instrumenterReport,
  );

  if (omitPlatform) {
    Component userCode = new Component(
      nameRoot: component.root,
      uriToSource: new Map<Uri, Source>.from(component.uriToSource),
    );
    userCode.setMainMethodAndMode(component.mainMethodName, true);
    for (Library library in component.libraries) {
      if (!library.importUri.isScheme("dart")) {
        userCode.libraries.add(library);
      }
    }
    component = userCode;
  }
  return component;
}

void addIfWantedProcedures(
  InstrumenterConfig config,
  List<Procedure> output,
  List<Procedure> input,
) {
  for (Procedure p in input) {
    if (p.function.body == null) continue;
    // Yielding functions doesn't work well with the begin/end scheme.
    if (p.function.dartAsyncMarker == AsyncMarker.SyncStar) continue;
    if (p.function.dartAsyncMarker == AsyncMarker.AsyncStar) continue;
    if (config.includeProcedure(p)) {
      output.add(p);
    }
  }
}

void addIfWantedConstructors(
  InstrumenterConfig config,
  List<Constructor> output,
  List<Constructor> input,
) {
  for (Constructor c in input) {
    if (c.isExternal) continue;
    if (config.includeConstructor(c)) {
      output.add(c);
    }
  }
}

String getNodeName(TreeNode n) {
  if (n is Procedure) return getProcedureName(n);
  if (n is Constructor) return getConstructorName(n);
  throw "unknown node for naming: $n";
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

Map<String, Set<String>> setupWantedMap(
  List<String> candidates,
  List<String> candidatesRaw,
) {
  Map<String, Set<String>> wanted = {};
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
  return wanted;
}

void initializeAndReport(
  InstrumenterConfig config,
  Procedure mainProcedure,
  Procedure initializeProcedure,
  List<String> namesById,
  Procedure instrumenterReport,
) {
  mainProcedure.enclosingLibrary.dependencies.add(
    new LibraryDependency.import(initializeProcedure.enclosingLibrary),
  );
  Block block = new Block([
    new ExpressionStatement(
      new StaticInvocation(
        initializeProcedure,
        config.createBeforeArguments(namesById),
      ),
    ),
    new TryFinally(
      mainProcedure.function.body as Statement,
      new ExpressionStatement(
        new StaticInvocation(
          instrumenterReport,
          config.createAfterArguments(namesById),
        ),
      ),
    ),
  ]);
  mainProcedure.function.body = block;
  block.parent = mainProcedure.function;
}

void wrapProcedure(
  InstrumenterConfig config,
  Procedure p,
  List<String> namesById,
  Procedure instrumenterEnter,
  Procedure instrumenterExit,
) {
  int id = namesById.length;
  namesById.add("${p.fileUri.pathSegments.last}|${getProcedureName(p)}");
  Block block = new Block([
    new ExpressionStatement(
      new StaticInvocation(
        instrumenterEnter,
        config.createEnterArguments(id, p),
      ),
    ),
    p.function.body as Statement,
  ]);
  TryFinally tryFinally = new TryFinally(
    block,
    new ExpressionStatement(
      new StaticInvocation(instrumenterExit, config.createExitArguments(id, p)),
    ),
  );
  p.function.body = tryFinally;
  tryFinally.parent = p.function;
}

void wrapConstructor(
  InstrumenterConfig config,
  Constructor c,
  List<String> namesById,
  Procedure instrumenterEnter,
  Procedure instrumenterExit,
) {
  int id = namesById.length;
  namesById.add("${c.fileUri.pathSegments.last}|${getConstructorName(c)}");
  Arguments enterArguments = config.createEnterArguments(id, c);
  Arguments exitArguments = config.createExitArguments(id, c);
  if (c.function.body == null || c.function.body is EmptyStatement) {
    // We just completely replace the body.
    Block block = new Block([
      new ExpressionStatement(
        new StaticInvocation(instrumenterEnter, enterArguments),
      ),
      new ExpressionStatement(
        new StaticInvocation(instrumenterExit, exitArguments),
      ),
    ]);
    c.function.body = block;
    block.parent = c.function;
    return;
  }

  // We retain the original body as with procedures.
  Block block = new Block([
    new ExpressionStatement(
      new StaticInvocation(instrumenterEnter, enterArguments),
    ),
    c.function.body as Statement,
  ]);
  TryFinally tryFinally = new TryFinally(
    block,
    new ExpressionStatement(
      new StaticInvocation(
        instrumenterExit,
        new Arguments([new IntLiteral(id)]),
      ),
    ),
  );
  c.function.body = tryFinally;
  tryFinally.parent = c.function;
}

class _CollectCallsVisitor extends RecursiveVisitor {
  static Set<String> collectCalls(TreeNode? node) {
    if (node == null) return const {};
    _CollectCallsVisitor visitor = new _CollectCallsVisitor._();
    node.accept(visitor);
    return visitor.collected;
  }

  Set<String> collected = {};

  _CollectCallsVisitor._();

  @override
  void visitStaticInvocation(StaticInvocation node) {
    collected.add(_extractUsedName(node));
    return super.visitStaticInvocation(node);
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    collected.add(_extractUsedName(node));
    return super.visitInstanceInvocation(node);
  }
}

class _InvocationWrapperTransformer extends Transformer {
  static void wrap(
    InstrumenterConfig config,
    Member member,
    Set<String> wantedNames,
    List<String> namesById,
    Procedure instrumenterEnter,
  ) {
    _InvocationWrapperTransformer transformer =
        new _InvocationWrapperTransformer._(
          config,
          member,
          wantedNames,
          namesById,
          instrumenterEnter,
        );
    member.transformChildren(transformer);
  }

  final InstrumenterConfig config;
  final Member member;
  final Set<String> wantedNames;
  final List<String> namesById;
  final Procedure instrumenterEnter;

  _InvocationWrapperTransformer._(
    this.config,
    this.member,
    this.wantedNames,
    this.namesById,
    this.instrumenterEnter,
  );

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    if (wantedNames.contains(_extractUsedName(node))) {
      return _wrapInvocation(node);
    }
    return node;
  }

  @override
  TreeNode visitInstanceInvocation(InstanceInvocation node) {
    node.transformChildren(this);
    if (wantedNames.contains(_extractUsedName(node))) {
      return _wrapInvocation(node);
    }
    return node;
  }

  BlockExpression _wrapInvocation(InvocationExpression node) {
    int id = namesById.length;
    namesById.add(
      node.location?.toString() ??
          "${member.fileUri.pathSegments.last}"
              "|${getNodeName(member)}"
              "|${node.name.text}",
    );
    return BlockExpression(
      new Block([
        new ExpressionStatement(
          new StaticInvocation(
            instrumenterEnter,
            config.createEnterArguments(id, member),
          ),
        ),
      ]),
      node,
    );
  }
}

String _extractUsedName(InvocationExpression node) {
  String result = node.name.text;
  if (node is StaticInvocation &&
      (node.target.isExtensionMember || node.target.isExtensionTypeMember)) {
    var name = extractQualifiedNameFromExtensionMember(node.target);
    if (name != null) {
      var index = name.lastIndexOf(".");
      if (index > 0) {
        index++;
        result = name.substring(index);
      }
    }
  }
  return result;
}
