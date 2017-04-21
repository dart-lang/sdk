// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library test.kernel.closures.suite;

import 'dart:async' show Future;

import 'dart:io' show Directory, File, Platform;

import 'package:analyzer/src/generated/sdk.dart' show DartSdk;

import 'package:analyzer/src/kernel/loader.dart'
    show DartLoader, DartOptions, createDartSdk;

import 'package:kernel/target/targets.dart' show Target, TargetFlags, getTarget;

import 'kernel_chain.dart'
    show MatchExpectation, Print, ReadDill, SanityCheck, WriteDill;

import 'package:testing/testing.dart'
    show
        Chain,
        ChainContext,
        Result,
        StdioProcess,
        Step,
        TestDescription,
        runMe;

import 'package:kernel/ast.dart' show Program;

import 'package:kernel/transformations/closure_conversion.dart'
    as closure_conversion;

import 'package:package_config/discovery.dart' show loadPackagesFile;

class TestContext extends ChainContext {
  final Uri vm;

  final Uri packages;

  final DartOptions options;

  final DartSdk dartSdk;

  final List<Step> steps;

  TestContext(String sdk, this.vm, Uri packages, bool strongMode, this.dartSdk,
      bool updateExpectations)
      : packages = packages,
        options = new DartOptions(
            strongMode: strongMode,
            sdk: sdk,
            packagePath: packages.toFilePath()),
        steps = <Step>[
          const Kernel(),
          const Print(),
          const SanityCheck(),
          const ClosureConversion(),
          const Print(),
          const SanityCheck(),
          new MatchExpectation(".expect",
              updateExpectations: updateExpectations),
          const WriteDill(),
          const ReadDill(),
          // TODO(29143): uncomment this when Vectors are added to VM.
          //const Run(),
        ];

  Future<DartLoader> createLoader() async {
    Program repository = new Program();
    return new DartLoader(repository, options, await loadPackagesFile(packages),
        dartSdk: dartSdk);
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

Future<bool> fileExists(Uri base, String path) async {
  return await new File.fromUri(base.resolve(path)).exists();
}

Future<TestContext> createContext(
    Chain suite, Map<String, String> environment) async {
  const String suggestion = """Try building the patched SDK by running
    'tools/build.py patched_sdk'""";

  // TODO(karlklose): The path is different on MacOS.
  String sdk = "out/DebugX64/patched_sdk/";
  Uri sdkUri = Uri.base.resolve(sdk);
  const String asyncDart = "lib/async/async.dart";
  if (!await fileExists(sdkUri, asyncDart)) {
    throw "Couldn't find the patched SDK. $suggestion";
  }
  const String asyncSources = "lib/async/async_sources.gypi";
  if (await fileExists(sdkUri, asyncSources)) {
    throw "Found '$asyncSources' in '$sdk', so it isn't a patched SDK. "
        "$suggestion";
  }

  // TODO(karlklose): select the VM based on the mode.
  Uri vm = Uri.base.resolve("out/ReleaseX64/dart");

  Uri packages = Uri.base.resolve(".packages");
  bool strongMode = false;
  bool updateExpectations = const String.fromEnvironment("updateExpectations",
          defaultValue: "false") ==
      "true";
  return new TestContext(sdk, vm, packages, strongMode,
      createDartSdk(sdk, strongMode: strongMode), updateExpectations);
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
      String path = description.file.path;
      Uri uri = Uri.base.resolve(path);
      loader.loadProgram(uri, target: target);
      var program = loader.program;
      for (var error in loader.errors) {
        return fail(program, "$error");
      }
      target
        ..performModularTransformations(program)
        ..performGlobalTransformations(program);
      return pass(program);
    } catch (e, s) {
      return crash(e, s);
    }
  }
}

class ClosureConversion extends Step<Program, Program, TestContext> {
  const ClosureConversion();

  String get name => "closure conversion";

  Future<Result<Program>> run(Program program, TestContext testContext) async {
    try {
      program = closure_conversion.transformProgram(program);
      return pass(program);
    } catch (e, s) {
      return crash(e, s);
    }
  }
}

class Run extends Step<Uri, int, TestContext> {
  const Run();

  String get name => "run";

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

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
