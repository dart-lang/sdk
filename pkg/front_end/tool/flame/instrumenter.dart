// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/util/options.dart';
import 'package:front_end/src/base/processed_options.dart';

import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/kernel.dart';

import '../_fasta/additional_targets.dart';
import '../_fasta/command_line.dart';
import '../_fasta/compile.dart' as fasta_compile;

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
  List<String> arguments = [];
  bool doCount = false;
  for (String arg in inputArguments) {
    if (arg == "--count") {
      doCount = true;
    } else if (arg.startsWith("--candidates=")) {
      candidates.add(arg.substring("--candidates=".length));
    } else {
      arguments.add(arg);
    }
  }
  bool reportCandidates = candidates.isEmpty;
  setupWantedMap(candidates);

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
      if (!reportCandidates || doCount) {
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
      if (!procedureNamesWantedInFile.contains(name)) {
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
      if (!constructorNamesWantedInFile.contains(name)) {
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

void setupWantedMap(List<String> candidates) {
  for (String filename in candidates) {
    File f = new File(filename);
    if (!f.existsSync()) throw "$filename doesn't exist.";
    for (String line in f.readAsLinesSync()) {
      String file = line.substring(0, line.indexOf("|"));
      String displayName = line.substring(line.indexOf("|") + 1);
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
  ChildReplacer childReplacer;
  try {
    childReplacer = getBody(mainProcedure.function);
  } catch (e) {
    throw "$mainProcedure: $e";
  }

  Block block = new Block([
    new ExpressionStatement(new StaticInvocation(
        initializeProcedure,
        new Arguments([
          new IntLiteral(procedures.length + constructors.length),
          new BoolLiteral(reportCandidates),
        ]))),
    new TryFinally(
        childReplacer.originalChild as Statement,
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
  childReplacer.replacer(block);
}

class ChildReplacer {
  final void Function(TreeNode replacement) replacer;
  final TreeNode originalChild;

  ChildReplacer(this.replacer, this.originalChild);
}

ChildReplacer getBody(FunctionNode functionNode) {
  // Is this an originally non-sync, but now transformed method?
  if (functionNode.dartAsyncMarker != AsyncMarker.Sync &&
      functionNode.dartAsyncMarker != functionNode.asyncMarker) {
    if (functionNode.dartAsyncMarker == AsyncMarker.Async) {
      // It was originally an async method. (this will work for the VM async
      // transformation).
      Block block = functionNode.body as Block;
      FunctionDeclaration functionDeclaration = block.statements
          .firstWhere((s) => s is FunctionDeclaration) as FunctionDeclaration;
      TryCatch tryCatch = functionDeclaration.function.body as TryCatch;
      Block tryCatchBlock = tryCatch.body as Block;
      LabeledStatement labeledStatement =
          tryCatchBlock.statements[0] as LabeledStatement;
      Block labeledStatementBlock = labeledStatement.body as Block;
      return new ChildReplacer((TreeNode newChild) {
        Block newBlock = new Block([newChild as Statement]);
        labeledStatement.body = newBlock;
        newBlock.parent = labeledStatement;
      }, labeledStatementBlock);
    } else if (functionNode.dartAsyncMarker == AsyncMarker.SyncStar) {
      // It was originally a sync* method. This will work for the VM
      // transformation.
      Block block = functionNode.body as Block;
      FunctionDeclaration functionDeclaration = block.statements
          .firstWhere((s) => s is FunctionDeclaration) as FunctionDeclaration;
      Block functionDeclarationBlock =
          functionDeclaration.function.body as Block;
      Block nestedBlock = functionDeclarationBlock.statements[0] as Block;
      return new ChildReplacer((TreeNode newChild) {
        functionDeclarationBlock.statements[0] = newChild as Statement;
        newChild.parent = functionDeclarationBlock;
      }, nestedBlock);
    } else {
      throw "Unsupported: ${functionNode.dartAsyncMarker}: "
          "${functionNode.body}";
    }
  } else {
    // Should be a regular sync method.
    assert(functionNode.dartAsyncMarker == AsyncMarker.Sync);
    assert(functionNode.asyncMarker == AsyncMarker.Sync);
    return new ChildReplacer((TreeNode newChild) {
      functionNode.body = newChild as Statement;
      newChild.parent = functionNode;
    }, functionNode.body as TreeNode);
  }
}

void wrapProcedure(Procedure p, int id, Procedure instrumenterEnter,
    Procedure instrumenterExit) {
  ChildReplacer childReplacer;
  try {
    childReplacer = getBody(p.function);
  } catch (e) {
    throw "$p: $e";
  }

  Block block = new Block([
    new ExpressionStatement(new StaticInvocation(
        instrumenterEnter, new Arguments([new IntLiteral(id)]))),
    childReplacer.originalChild as Statement
  ]);
  TryFinally tryFinally = new TryFinally(
      block,
      new ExpressionStatement(new StaticInvocation(
          instrumenterExit, new Arguments([new IntLiteral(id)]))));
  childReplacer.replacer(tryFinally);
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
