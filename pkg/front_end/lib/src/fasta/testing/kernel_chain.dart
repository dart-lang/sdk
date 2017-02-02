// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// TODO(ahe): Copied from closure_conversion branch of kernel, remove this file
// when closure_conversion is merged with master.

library kernel.testing.kernel_chain;

import 'dart:async' show
    Future;

import 'dart:io' show
    Directory,
    File,
    IOSink,
    Platform;

import 'dart:typed_data' show
    Uint8List;

import 'package:kernel/kernel.dart' show
    Repository,
    loadProgramFromBinary;

import 'package:kernel/text/ast_to_text.dart' show
    Printer;

import 'package:testing/testing.dart' show
    Result,
    StdioProcess,
    Step;

import 'package:kernel/ast.dart' show
    Library,
    Program;

import 'package:kernel/verifier.dart' show
    VerifyingVisitor;

import 'package:kernel/binary/ast_to_binary.dart' show
    BinaryPrinter;

import 'package:kernel/binary/ast_from_binary.dart' show
    BinaryBuilder;

import 'package:kernel/binary/loader.dart' show
    BinaryLoader;

import 'package:analyzer/src/generated/sdk.dart' show
    DartSdk;

import 'package:kernel/analyzer/loader.dart' show
    DartLoader,
    DartOptions,
    createDartSdk;

import 'package:kernel/target/targets.dart' show
    Target,
    TargetFlags,
    getTarget;

import 'package:kernel/repository.dart' show
    Repository;

import 'package:testing/testing.dart' show
    Chain,
    ChainContext,
    Result,
    StdioProcess,
    Step,
    TestDescription;

import 'package:kernel/ast.dart' show
    Program;

import 'package:package_config/discovery.dart' show
    loadPackagesFile;

typedef Future<TestContext> TestContextConstructor(
    Chain suite, Map<String, String> environment, String sdk, Uri vm,
    Uri packages, bool strongMode, DartSdk dartSdk, bool updateExpectations);

Future<bool> fileExists(Uri base, String path) async {
  return await new File.fromUri(base.resolve(path)).exists();
}

abstract class TestContext extends ChainContext {
  final Uri vm;

  final Uri packages;

  final DartOptions options;

  final DartSdk dartSdk;

  TestContext(String sdk, this.vm, Uri packages, bool strongMode, this.dartSdk)
      : packages = packages,
        options = new DartOptions(strongMode: strongMode, sdk: sdk,
            packagePath: packages.toFilePath());

  Future<DartLoader> createLoader() async {
    Repository repository = new Repository();
    return new DartLoader(repository, options, await loadPackagesFile(packages),
        ignoreRedirectingFactories: false, dartSdk: dartSdk);
  }

  static Future<TestContext> create(Chain suite,
      Map<String, String> environment,
      TestContextConstructor constructor) async {
    const String suggestion =
        "Try checking the value of environment variable 'DART_AOT_SDK', "
        "it should point to a patched SDK.";
    String sdk = await getEnvironmentVariable(
        "DART_AOT_SDK", Environment.directory,
        "Please define environment variable 'DART_AOT_SDK' to point to a "
        "patched SDK.",
        (String n) => "Couldn't locate '$n'. $suggestion");
    Uri sdkUri = Uri.base.resolve("$sdk/");
    const String asyncDart = "lib/async/async.dart";
    if (!await fileExists(sdkUri, asyncDart)) {
      throw "Couldn't find '$asyncDart' in '$sdk'. $suggestion";
    }
    const String asyncSources = "lib/async/async_sources.gypi";
    if (await fileExists(sdkUri, asyncSources)) {
      throw "Found '$asyncSources' in '$sdk', so it isn't a patched SDK. "
          "$suggestion";
    }

    String vmPath = await getEnvironmentVariable(
        "DART_AOT_VM", Environment.file,
        "Please define environment variable 'DART_AOT_VM' to point to a "
        "Dart VM that reads .dill files.",
        (String n) => "Couldn't locate '$n'. Please check the value of "
            "environment variable 'DART_AOT_VM', it should point to a "
            "Dart VM that reads .dill files.");
    Uri vm = Uri.base.resolve(vmPath);

    Uri packages = Uri.base.resolve(".packages");
    bool strongMode = false;
    bool updateExpectations = environment["updateExpectations"] != "false";
    return constructor(suite, environment, sdk, vm, packages, strongMode,
        createDartSdk(sdk, strongMode: strongMode), updateExpectations);
  }
}

enum Environment {
  directory,
  file,
}

Future<String> getEnvironmentVariable(
    String name, Environment kind, String undefined, notFound(String n)) async {
  String result = Platform.environment[name];
  if (result == null) {
    throw undefined;
  }
  switch (kind) {
    case Environment.directory:
      if (!await new Directory(result).exists()) throw notFound(result);
      break;

    case Environment.file:
      if (!await new File(result).exists()) throw notFound(result);
      break;
  }
  return result;
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
      Program program =
          loader.loadProgram(description.uri, target: target);
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


class Print extends Step<Program, Program, dynamic> {
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

class Verify extends Step<Program, Program, dynamic> {
  final bool fullCompile;

  const Verify(this.fullCompile);

  String get name => "verify";

  Future<Result<Program>> run(Program program, TestContext testContext) async {
    try {
      program.accept(new VerifyingVisitor()..isOutline = !fullCompile);
      return pass(program);
    } catch (e, s) {
      return new Result<Program>(
          null, testContext.expectationSet["VerificationError"], e, s);
    }
  }
}

class MatchExpectation extends Step<Program, Program, dynamic> {
  final String suffix;

  // TODO(ahe): This is true by default which doesn't match well with the class
  // name.
  final bool updateExpectations;

  const MatchExpectation(this.suffix, {this.updateExpectations: true});

  String get name => "match expectations";

  Future<Result<Program>> run(Program program, _) async {
    Library library = program.libraries.firstWhere(
        (Library library) => library.importUri.scheme != "dart");
    Uri uri = library.importUri;
    StringBuffer buffer = new StringBuffer();
    new Printer(buffer).writeLibraryFile(library);

    bool updateExpectations = this.updateExpectations;
    if (uri.path.contains("/test/fasta/rasta/")) {
      // TODO(ahe): Remove this. Short term, we don't want to automatically
      // update rasta expectations, as we have too many failures.
      updateExpectations = false;
    }
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
      return fail(program, """
Please create file ${expectedFile.path} with this content:
$buffer""");
    }
  }
}

class WriteDill extends Step<Program, Uri, dynamic> {
  const WriteDill();

  String get name => "write .dill";

  Future<Result<Uri>> run(Program program, _) async {
    Directory tmp = await Directory.systemTemp.createTemp();
    Uri uri = tmp.uri.resolve("generated.dill");
    File generated = new File.fromUri(uri);
    IOSink sink = generated.openWrite();
    try {
      new BinaryPrinter(sink).writeProgramFile(program);
    } catch (e, s) {
      return fail(uri, e, s);
    } finally {
      print("Wrote `${generated.path}`");
      await sink.close();
    }
    return pass(uri);
  }
}

class ReadDill extends Step<Uri, Uri, dynamic> {
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

class Copy extends Step<Program, Program, dynamic> {
  const Copy();

  String get name => "copy program";

  Future<Result<Program>> run(Program program, _) async {
    BytesCollector sink = new BytesCollector();
    new BinaryPrinter(sink).writeProgramFile(program);
    Uint8List bytes = sink.collect();
    BinaryLoader loader = new BinaryLoader(new Repository());
    return pass(new BinaryBuilder(loader, bytes).readProgramFile());
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
      process = await StdioProcess.run(
          context.vm.toFilePath(), [generated.path, "Hello, World!"]);
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
  StdioProcess process = await StdioProcess.run(
      "diff", <String>["-u", expected.toFilePath(), "-"], input: actual);
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
