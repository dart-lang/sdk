import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/binary/ast_from_binary.dart';

import "simple_stats.dart";

/// This pass all parameters after "--" to the compiler (via `compileEntryPoint`
/// via the helper `compile_benchmark_helper.dart`). It is meant to "benchmark"/
/// instrument the compiler to give insights into specific runs, i.e. specific
/// compiles (compiling program `a` and program `b` might have different
/// characteristics). Said another way, it will always instrument and give
/// insights on *the compiler*, not the program it's asked to compile (not
/// directly anyway -- if you want to know if that program successfully
/// exercises a specific part of the compiler it _does_ do that).

final Uri benchmarkHelper =
    Platform.script.resolve("compile_benchmark_helper.dart");

void main(List<String> args) {
  List<String>? arguments;
  bool tryToAnnotate = false;
  bool tryToSlowDown = false;
  bool timeInsteadOfCount = false;
  for (int i = 0; i < args.length; i++) {
    if (args[i] == "--tryToAnnotate") {
      tryToAnnotate = true;
    } else if (args[i] == "--tryToSlowDown") {
      tryToSlowDown = true;
    } else if (args[i] == "--timeInsteadOfCount") {
      timeInsteadOfCount = true;
    } else if (args[i] == "--") {
      arguments = args.sublist(i + 1);
      break;
    } else {
      throw "Unknown argument '${args[i]}'";
    }
  }
  if (arguments == null || arguments.isEmpty) {
    throw "No arguments given to compiler.\n"
        "Give arguments as `dart compile_benchmark.dart -- "
        "argument1 argument2 (etc)`";
  }

  Directory tmp = Directory.systemTemp.createTempSync("benchmark");
  try {
    // Compile the helper to get a dill we can compile with.
    final Uri helperDill = tmp.uri.resolve("compile.dill");

    print("Compiling $benchmarkHelper into $helperDill");
    runXTimes(1, [
      benchmarkHelper.toString(),
      benchmarkHelper.toString(),
      "-o",
      helperDill.toString(),
    ]);
    File f = new File.fromUri(helperDill);
    if (!f.existsSync()) throw "$f doesn't exist!";

    List<int> dillData = new File.fromUri(helperDill).readAsBytesSync();
    doWork(
      tmp,
      dillData,
      arguments,
      tryToAnnotate: tryToAnnotate,
      tryToSlowDown: tryToSlowDown,
      timeInsteadOfCount: timeInsteadOfCount,
    );
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

/// Perform asked operations on the dill data provided.
///
/// Will save files into the provided tmp directory, do timing or counting
/// instructions and run that with the arguments passed, and then do comparative
/// runs of transformed/non-transformed versions of the dill. The possible
/// transformations are:
/// * [tryToAnnotate] which will add a `@pragma("vm:prefer-inline")` annotation
///   to each procedure one at a time.
/// * [tryToSlowDown] which will add a busywait for approximately 0.002 ms to
///   each procedure one at a time. (Unsurprisingly this makes it slower
///   proportional to the number of times the procedure is called, so the
///   counting annotation is likely at least as useful).
///
void doWork(Directory tmp, List<int> dillData, List<String> arguments,
    {bool tryToAnnotate: false,
    bool tryToSlowDown: false,
    bool timeInsteadOfCount: false}) {
  File f = new File.fromUri(tmp.uri.resolve("a.dill"));
  f.writeAsBytesSync(dillData);
  Uri dillOrgInTmp = f.uri;
  print("Wrote to $f");

  List<Procedure> sortedProcedures;
  if (timeInsteadOfCount) {
    sortedProcedures = doTimingInstrumentation(dillData, tmp, arguments);
  } else {
    sortedProcedures = doCountingInstrumentation(dillData, tmp, arguments);
  }
  print("\n\n");

  bool didSomething = false;

  if (tryToAnnotate) {
    didSomething = true;
    for (Procedure p in sortedProcedures) {
      print("Prefer inline $p (${p.location})");
      Uri preferredInlined = preferInlineProcedure(
          dillData,
          tmp.uri,
          (lib) => lib.importUri == p.enclosingLibrary.importUri,
          p.enclosingClass?.name,
          p.name.text);

      print("\nOriginal runs:");
      List<int> runtimesA =
          runXTimes(5, [dillOrgInTmp.toString(), ...arguments]);

      print("\nModified runs:");
      List<int> runtimesB =
          runXTimes(5, [preferredInlined.toString(), ...arguments]);

      print(SimpleTTestStat.ttest(runtimesB, runtimesA));
      print("\n------------\n");
    }
  }

  if (tryToSlowDown) {
    didSomething = true;
    for (Procedure p in sortedProcedures) {
      Uri? busyWaiting = busyWaitProcedure(
          dillData,
          tmp.uri,
          (lib) => lib.importUri == p.enclosingLibrary.importUri,
          p.enclosingClass?.name,
          p.name.text);
      if (busyWaiting == null) continue;

      print("Slow down $p (${p.location})");

      print("\nOriginal runs:");
      List<int> runtimesA =
          runXTimes(2, [dillOrgInTmp.toString(), ...arguments]);

      print("\nModified runs:");
      List<int> runtimesB =
          runXTimes(2, [busyWaiting.toString(), ...arguments]);

      print(SimpleTTestStat.ttest(runtimesB, runtimesA));
      print("\n------------\n");
    }
  }

  if (!didSomething) {
    runXTimes(10, [dillOrgInTmp.toString(), ...arguments]);
  }
}

/// Instrument the [dillData] so that each procedure-call can be registered
/// (in package:front_end) and we find out how many times each procedure is
/// called for a specific run, then run it, print the result and return the
/// procedures in sorted order (most calls first).
List<Procedure> doCountingInstrumentation(
    List<int> dillData, Directory tmp, List<String> arguments) {
  Instrumented instrumented = instrumentCallsCount(dillData, tmp.uri);
  List<dynamic> stdout = [];
  runXTimes(1, [instrumented.dill.toString(), ...arguments], stdout);
  List<int> procedureCountsTmp = new List<int>.from(jsonDecode(stdout.single));
  List<IntPair> procedureCounts = [];
  for (int i = 0; i < procedureCountsTmp.length; i += 2) {
    procedureCounts
        .add(new IntPair(procedureCountsTmp[i], procedureCountsTmp[i + 1]));
  }
  // Sort highest call-count first.
  procedureCounts.sort((a, b) => b.value - a.value);
  List<Procedure> sortedProcedures = [];
  for (IntPair p in procedureCounts) {
    if (p.value > 1000) {
      Procedure procedure = instrumented.procedures[p.key];
      String location = procedure.location.toString();
      if (location.length > 50) {
        location = location.substring(location.length - 50);
      }
      print("Called $procedure ${p.value} times ($location)");
      sortedProcedures.add(procedure);
    }
  }
  return sortedProcedures;
}

/// Instrument the [dillData] so that each (sync) procedure-call can be timed
/// (time on stack, i.e. not only the procedure itself, but also the
/// procedure-calls it makes) (in package:front_end) and we find out how long
/// each procedure is on the stack for a specific run, then run it, print the
/// result and return the procedures in sorted order (most time on stack first).
List<Procedure> doTimingInstrumentation(
    List<int> dillData, Directory tmp, List<String> arguments) {
  Instrumented instrumented = instrumentCallsTiming(dillData, tmp.uri);
  List<dynamic> stdout = [];
  runXTimes(1, [instrumented.dill.toString(), ...arguments], stdout);
  List<int> procedureTimeTmp = new List<int>.from(jsonDecode(stdout.single));
  List<IntPair> procedureTime = [];
  for (int i = 0; i < procedureTimeTmp.length; i += 2) {
    procedureTime
        .add(new IntPair(procedureTimeTmp[i], procedureTimeTmp[i + 1]));
  }
  // Sort highest time-on-stack first.
  procedureTime.sort((a, b) => b.value - a.value);
  List<Procedure> sortedProcedures = [];
  for (IntPair p in procedureTime) {
    if (p.value > 1000) {
      Procedure procedure = instrumented.procedures[p.key];
      String location = procedure.location.toString();
      if (location.length > 50) {
        location = location.substring(location.length - 50);
      }
      print("$procedure was on stack for ${p.value} microseconds ($location)");
      sortedProcedures.add(procedure);
    }
  }
  return sortedProcedures;
}

class IntPair {
  final int key;
  final int value;

  IntPair(this.key, this.value);

  @override
  String toString() {
    return "IntPair[$key: $value]";
  }
}

/// Adds the annotation `@pragma("vm:prefer-inline")` to the specified procedure
/// and serialize the resulting dill into `b.dill` (return uri).
///
/// The annotation is copied from the [preferInlineMe] method in the helper.
Uri preferInlineProcedure(List<int> dillData, Uri tmp,
    bool libraryMatcher(Library lib), String? className, String procedureName) {
  Component component = new Component();
  new BinaryBuilder(dillData, disableLazyReading: true)
      .readComponent(component);
  Procedure preferInlineMeProcedure = getProcedure(component,
      (lib) => lib.fileUri == benchmarkHelper, null, "preferInlineMe");
  ConstantExpression annotation =
      preferInlineMeProcedure.annotations.single as ConstantExpression;
  Procedure markProcedure =
      getProcedure(component, libraryMatcher, className, procedureName);
  markProcedure.addAnnotation(
      new ConstantExpression(annotation.constant, annotation.type));

  Uint8List newDillData = serializeComponent(component);
  File f = new File.fromUri(tmp.resolve("b.dill"));
  f.writeAsBytesSync(newDillData);
  return f.uri;
}

/// Makes the procedure specified call [busyWait] from the helper and serialize
/// the resulting dill into `c.dill` (return uri).
///
/// This will make the procedure busy-wait approximately 0.002 ms for each
/// invocation (+ whatever overhead and imprecision).
Uri? busyWaitProcedure(List<int> dillData, Uri tmp,
    bool libraryMatcher(Library lib), String? className, String procedureName) {
  Component component = new Component();
  new BinaryBuilder(dillData, disableLazyReading: true)
      .readComponent(component);
  Procedure busyWaitProcedure = getProcedure(
      component, (lib) => lib.fileUri == benchmarkHelper, null, "busyWait");

  Procedure markProcedure =
      getProcedure(component, libraryMatcher, className, procedureName);
  if (markProcedure.function.body == null) return null;

  Statement orgBody = markProcedure.function.body as Statement;
  markProcedure.function.body = new Block([
    new ExpressionStatement(new StaticInvocation(
        busyWaitProcedure, new Arguments([new IntLiteral(2 /* 0.002 ms */)]))),
    orgBody
  ])
    ..parent = markProcedure.function;

  Uint8List newDillData = serializeComponent(component);
  File f = new File.fromUri(tmp.resolve("c.dill"));
  f.writeAsBytesSync(newDillData);
  return f.uri;
}

/// Instrument the [dillData] so that each procedure-call can be registered
/// (in package:front_end) and we find out how many times each procedure is
/// called for a specific run.
///
/// Uses the [registerCall] in the helper.
/// Numbers each procedure, saves the instrumented dill and returns both the
/// dill and the list of procedures so that procedure i in the list will be
/// annotated with a call to `registerCall(i)`.
Instrumented instrumentCallsCount(List<int> dillData, Uri tmp) {
  Component component = new Component();
  new BinaryBuilder(dillData, disableLazyReading: true)
      .readComponent(component);
  Procedure registerCallProcedure = getProcedure(
      component, (lib) => lib.fileUri == benchmarkHelper, null, "registerCall");
  RegisterCallTransformer registerCallTransformer =
      new RegisterCallTransformer(registerCallProcedure);
  component.accept(registerCallTransformer);

  Uint8List newDillData = serializeComponent(component);
  File f = new File.fromUri(tmp.resolve("counting.dill"));
  f.writeAsBytesSync(newDillData);

  return new Instrumented(f.uri, registerCallTransformer.procedures);
}

/// Instrument the [dillData] so that each (sync) procedure-call can be timed
/// (time on stack, i.e. not only the procedure itself, but also the
/// procedure-calls it makes) (in package:front_end) and we find out how long
/// each procedure is on the stack for a specific run.
///
/// Uses [registerCallStart] and [registerCallEnd] from the helper.
/// Numbers each sync procedure, saves the instrumented dill and returns both
/// the dill and the list of procedures so that procedure i in the list will be
/// annotated with a call-pair to `registerCallStart(i)` and
/// `registerCallEnd(i)`.
Instrumented instrumentCallsTiming(List<int> dillData, Uri tmp) {
  Component component = new Component();
  new BinaryBuilder(dillData, disableLazyReading: true)
      .readComponent(component);
  Procedure registerCallStartProcedure = getProcedure(component,
      (lib) => lib.fileUri == benchmarkHelper, null, "registerCallStart");
  Procedure registerCallEndProcedure = getProcedure(component,
      (lib) => lib.fileUri == benchmarkHelper, null, "registerCallEnd");
  RegisterTimeTransformer registerTimeTransformer = new RegisterTimeTransformer(
      registerCallStartProcedure, registerCallEndProcedure);
  component.accept(registerTimeTransformer);

  Uint8List newDillData = serializeComponent(component);
  File f = new File.fromUri(tmp.resolve("timing.dill"));
  f.writeAsBytesSync(newDillData);

  return new Instrumented(f.uri, registerTimeTransformer.procedures);
}

/// Class holding both the uri of a saved dill file and a list of procedures (in
/// order) that has some reference to the annotation added to the dill file.
class Instrumented {
  final Uri dill;
  final List<Procedure> procedures;

  Instrumented(this.dill, this.procedures);
}

class RegisterCallTransformer extends RecursiveVisitor {
  final Procedure registerCallProcedure;
  RegisterCallTransformer(this.registerCallProcedure);
  List<Procedure> procedures = [];

  @override
  void visitLibrary(Library node) {
    if (node.importUri.isScheme("package") &&
        node.importUri.pathSegments.first == "front_end") {
      super.visitLibrary(node);
    }
  }

  @override
  void visitProcedure(Procedure node) {
    if (node.function.body == null) return;
    int procedureNum = procedures.length;
    procedures.add(node);
    Statement orgBody = node.function.body as Statement;
    node.function.body = new Block([
      new ExpressionStatement(new StaticInvocation(registerCallProcedure,
          new Arguments([new IntLiteral(procedureNum)]))),
      orgBody
    ]);
    node.function.body!.parent = node.function;
  }
}

class RegisterTimeTransformer extends RecursiveVisitor {
  final Procedure registerCallStartProcedure;
  final Procedure registerCallEndProcedure;

  RegisterTimeTransformer(
      this.registerCallStartProcedure, this.registerCallEndProcedure);

  List<Procedure> procedures = [];

  @override
  void visitLibrary(Library node) {
    if (node.importUri.isScheme("package") &&
        node.importUri.pathSegments.first == "front_end") {
      super.visitLibrary(node);
    }
  }

  @override
  void visitProcedure(Procedure node) {
    if (node.function.body == null) return;
    if (node.function.dartAsyncMarker != AsyncMarker.Sync) return;
    int procedureNum = procedures.length;
    procedures.add(node);
    Statement orgBody = node.function.body as Statement;
    // Rewrite as
    // {
    //    registerCallStartProcedure(x);
    //    try {
    //      originalBody
    //    } finally {
    //      registerCallEndProcedure(x);
    //    }
    // }
    Block block = new Block([
      new ExpressionStatement(new StaticInvocation(registerCallStartProcedure,
          new Arguments([new IntLiteral(procedureNum)]))),
      new TryFinally(
        orgBody,
        new ExpressionStatement(new StaticInvocation(registerCallEndProcedure,
            new Arguments([new IntLiteral(procedureNum)]))),
      )
    ]);
    node.function.body = block;
    node.function.body!.parent = node.function;
  }
}

Procedure getProcedure(Component component, bool libraryMatcher(Library lib),
    String? className, String procedureName) {
  Library lib = component.libraries.where(libraryMatcher).single;
  List<Procedure> procedures = lib.procedures;
  if (className != null) {
    Class cls = lib.classes.where((c) => c.name == className).single;
    procedures = cls.procedures;
  }
  // TODO: This will fail for getter/setter pairs. Fix that.
  return procedures.where((p) => p.name.text == procedureName).single;
}

List<int> runXTimes(int x, List<String> arguments, [List<dynamic>? stdout]) {
  List<int> result = [];
  Stopwatch stopwatch = new Stopwatch()..start();
  for (int i = 0; i < x; i++) {
    stopwatch.reset();
    ProcessResult run = Process.runSync(Platform.resolvedExecutable, arguments,
        runInShell: true);
    int ms = stopwatch.elapsedMilliseconds;
    result.add(ms);
    print(ms);
    if (run.exitCode != 0) throw "Got exit code ${run.exitCode}";
    if (stdout != null) {
      stdout.add(run.stdout);
    }
  }
  return result;
}
