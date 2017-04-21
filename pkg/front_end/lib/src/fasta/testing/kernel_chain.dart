// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// TODO(ahe): Copied from closure_conversion branch of kernel, remove this file
// when closure_conversion is merged with master.

library kernel.testing.kernel_chain;

import 'dart:async' show Future;

import 'dart:io' show Directory, File, IOSink, Platform;

import 'dart:typed_data' show Uint8List;

import 'package:kernel/kernel.dart' show loadProgramFromBinary;

import 'package:kernel/text/ast_to_text.dart' show Printer;

import 'package:testing/testing.dart' show Result, StdioProcess, Step;

import 'package:kernel/ast.dart' show Library, Program;

import '../kernel/verifier.dart' show verifyProgram;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:analyzer/src/generated/sdk.dart' show DartSdk;

import 'package:analyzer/src/kernel/loader.dart'
    show DartLoader, DartOptions, createDartSdk;

import 'package:kernel/target/targets.dart' show Target, TargetFlags, getTarget;

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, StdioProcess, Step, TestDescription;

import 'package:kernel/ast.dart' show Program;

import 'package:package_config/discovery.dart' show loadPackagesFile;

import '../environment_variable.dart' show EnvironmentVariable;

typedef Future<TestContext> TestContextConstructor(
    Chain suite,
    Map<String, String> environment,
    Uri sdk,
    Uri vm,
    Uri packages,
    bool strongMode,
    DartSdk dartSdk,
    bool updateExpectations);

Future<bool> fileExists(Uri base, String path) async {
  return await new File.fromUri(base.resolve(path)).exists();
}

final EnvironmentVariable testConfigVariable = new EnvironmentVariable(
    "DART_CONFIGURATION",
    "It should be something like 'ReleaseX64', depending on which"
    " configuration you're testing.");

Future<Uri> computePatchedSdk() async {
  String config = await testConfigVariable.value;
  String path;
  switch (Platform.operatingSystem) {
    case "linux":
      path = "out/$config/patched_sdk";
      break;

    case "macos":
      path = "xcodebuild/$config/patched_sdk";
      break;

    case "windows":
      path = "build/$config/patched_sdk";
      break;

    default:
      throw "Unsupported operating system: '${Platform.operatingSystem}'.";
  }
  Uri sdk = Uri.base.resolve("$path/");
  const String asyncDart = "lib/async/async.dart";
  if (!await fileExists(sdk, asyncDart)) {
    throw "Couldn't find '$asyncDart' in '$sdk'.";
  }
  const String asyncSources = "lib/async/async_sources.gypi";
  if (await fileExists(sdk, asyncSources)) {
    throw "Found '$asyncSources' in '$sdk', so it isn't a patched SDK.";
  }
  return sdk;
}

Uri computeDartVm(Uri patchedSdk) {
  return patchedSdk.resolve(Platform.isWindows ? "../dart.exe" : "../dart");
}

abstract class TestContext extends ChainContext {
  final Uri vm;

  final Uri packages;

  final DartOptions options;

  final DartSdk dartSdk;

  TestContext(Uri sdk, this.vm, Uri packages, bool strongMode, this.dartSdk)
      : packages = packages,
        options = new DartOptions(
            strongMode: strongMode,
            sdk: sdk.toFilePath(),
            packagePath: packages.toFilePath());

  Future<DartLoader> createLoader() async {
    Program program = new Program();
    return new DartLoader(program, options, await loadPackagesFile(packages),
        ignoreRedirectingFactories: false, dartSdk: dartSdk);
  }

  static Future<TestContext> create(
      Chain suite,
      Map<String, String> environment,
      TestContextConstructor constructor) async {
    Uri sdk = await computePatchedSdk();
    Uri vm = computeDartVm(sdk);
    Uri packages = Uri.base.resolve(".packages");
    bool strongMode = false;
    bool updateExpectations = environment["updateExpectations"] == "true";
    return constructor(
        suite,
        environment,
        sdk,
        vm,
        packages,
        strongMode,
        createDartSdk(sdk.toFilePath(), strongMode: strongMode),
        updateExpectations);
  }
}

class Kernel extends Step<TestDescription, Program, TestContext> {
  const Kernel();

  String get name => "kernel";

  Future<Result<Program>> run(
      TestDescription description, TestContext testContext) async {
    try {
      DartLoader loader = await testContext.createLoader();
      Target target = getTarget(
          "vm", new TargetFlags(strongMode: testContext.options.strongMode));
      loader.loadProgram(description.uri, target: target);
      Program program = loader.program;
      for (var error in loader.errors) {
        return fail(program, "$error");
      }
      target.performModularTransformations(program);
      target.performGlobalTransformations(program);
      return pass(program);
    } catch (e, s) {
      return crash(e, s);
    }
  }
}

class Print extends Step<Program, Program, TestContext> {
  const Print();

  String get name => "print";

  Future<Result<Program>> run(Program program, _) async {
    StringBuffer sb = new StringBuffer();
    for (Library library in program.libraries) {
      Printer printer = new Printer(sb);
      if (library.importUri.scheme != "dart" &&
          library.importUri.scheme != "package") {
        printer.writeLibraryFile(library);
      }
    }
    print("$sb");
    return pass(program);
  }
}

class Verify extends Step<Program, Program, TestContext> {
  final bool fullCompile;

  const Verify(this.fullCompile);

  String get name => "verify";

  Future<Result<Program>> run(Program program, TestContext testContext) async {
    var errors = verifyProgram(program, isOutline: !fullCompile);
    if (errors.isEmpty) {
      return pass(program);
    } else {
      return new Result<Program>(
          null, testContext.expectationSet["VerificationError"], errors, null);
    }
  }
}

class MatchExpectation extends Step<Program, Program, TestContext> {
  final String suffix;

  // TODO(ahe): This is true by default which doesn't match well with the class
  // name.
  final bool updateExpectations;

  const MatchExpectation(this.suffix, {this.updateExpectations: false});

  String get name => "match expectations";

  Future<Result<Program>> run(Program program, _) async {
    Library library = program.libraries
        .firstWhere((Library library) => library.importUri.scheme != "dart");
    Uri uri = library.importUri;
    StringBuffer buffer = new StringBuffer();
    new Printer(buffer).writeLibraryFile(library);

    File expectedFile = new File("${uri.toFilePath()}$suffix");
    if (await expectedFile.exists()) {
      String expected = await expectedFile.readAsString();
      if (expected.trim() != "$buffer".trim()) {
        if (!updateExpectations) {
          String diff = await runDiff(expectedFile.uri, "$buffer");
          return fail(null, "$uri doesn't match ${expectedFile.uri}\n$diff");
        }
      } else {
        return pass(program);
      }
    }
    if (updateExpectations) {
      await openWrite(expectedFile.uri, (IOSink sink) {
        sink.writeln("$buffer".trim());
      });
      return pass(program);
    } else {
      return fail(
          program,
          """
Please create file ${expectedFile.path} with this content:
$buffer""");
    }
  }
}

class WriteDill extends Step<Program, Uri, TestContext> {
  const WriteDill();

  String get name => "write .dill";

  Future<Result<Uri>> run(Program program, _) async {
    Directory tmp = await Directory.systemTemp.createTemp();
    Uri uri = tmp.uri.resolve("generated.dill");
    File generated = new File.fromUri(uri);
    IOSink sink = generated.openWrite();
    try {
      new BinaryPrinter(sink).writeProgramFile(program);
      program.unbindCanonicalNames();
    } catch (e, s) {
      return fail(uri, e, s);
    } finally {
      print("Wrote `${generated.path}`");
      await sink.close();
    }
    return pass(uri);
  }
}

class ReadDill extends Step<Uri, Uri, TestContext> {
  const ReadDill();

  String get name => "read .dill";

  Future<Result<Uri>> run(Uri uri, _) async {
    try {
      loadProgramFromBinary(uri.toFilePath());
    } catch (e, s) {
      return fail(uri, e, s);
    }
    return pass(uri);
  }
}

class Copy extends Step<Program, Program, TestContext> {
  const Copy();

  String get name => "copy program";

  Future<Result<Program>> run(Program program, _) async {
    BytesCollector sink = new BytesCollector();
    new BinaryPrinter(sink).writeProgramFile(program);
    program.unbindCanonicalNames();
    Uint8List bytes = sink.collect();
    new BinaryBuilder(bytes).readProgram(program);
    return pass(program);
  }
}

class Run extends Step<Uri, int, TestContext> {
  const Run();

  String get name => "run";

  bool get isAsync => true;

  bool get isRuntime => true;

  Future<Result<int>> run(Uri uri, TestContext context) async {
    File generated = new File.fromUri(uri);
    StdioProcess process;
    try {
      process = await StdioProcess
          .run(context.vm.toFilePath(), [generated.path, "Hello, World!"]);
      print(process.output);
    } finally {
      generated.parent.delete(recursive: true);
    }
    return process.toResult();
  }
}

class BytesCollector implements Sink<List<int>> {
  final List<List<int>> lists = <List<int>>[];

  int length = 0;

  void add(List<int> data) {
    lists.add(data);
    length += data.length;
  }

  Uint8List collect() {
    Uint8List result = new Uint8List(length);
    int offset = 0;
    for (List<int> list in lists) {
      result.setRange(offset, offset += list.length, list);
    }
    lists.clear();
    length = 0;
    return result;
  }

  void close() {}
}

Future<String> runDiff(Uri expected, String actual) async {
  // TODO(ahe): Implement this for Windows.
  StdioProcess process = await StdioProcess
      .run("diff", <String>["-u", expected.toFilePath(), "-"], input: actual);
  return process.output;
}

Future openWrite(Uri uri, f(IOSink sink)) async {
  IOSink sink = new File.fromUri(uri).openWrite();
  try {
    await f(sink);
  } finally {
    await sink.close();
  }
  print("Wrote $uri");
}
