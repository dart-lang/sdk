// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.incremental_test;

import "dart:async" show Future;

import "dart:convert" show JsonEncoder;

import "dart:io" show File;

import "package:kernel/ast.dart" show Program;

import "package:testing/testing.dart"
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import "package:yaml/yaml.dart" show YamlMap, loadYamlNode;

import "package:front_end/src/api_prototype/front_end.dart"
    show CompilationMessage, CompilerOptions, Severity;

import "package:front_end/src/api_prototype/incremental_kernel_generator.dart"
    show IncrementalKernelGenerator;

import "package:front_end/src/api_prototype/memory_file_system.dart"
    show MemoryFileSystem;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/external_state_snapshot.dart'
    show ExternalStateSnapshot;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import "incremental_expectations.dart"
    show IncrementalExpectation, extractJsonExpectations;

import "incremental_source_files.dart" show expandDiff, expandUpdates;

const JsonEncoder json = const JsonEncoder.withIndent("  ");

final Uri base = Uri.parse('org-dartlang-test:///');

class Context extends ChainContext {
  final ProcessedOptions options;
  final ExternalStateSnapshot snapshot;
  final List<CompilationMessage> errors;

  final List<Step> steps = const <Step>[
    const ReadTest(),
    const FullCompile(),
    const IncrementalUpdates(),
  ];

  const Context(this.options, this.snapshot, this.errors);

  void reset() {
    errors.clear();
    snapshot.restore();
  }
}

class ReadTest extends Step<TestDescription, TestCase, Context> {
  const ReadTest();

  String get name => "read test";

  Future<Result<TestCase>> run(
      TestDescription description, Context context) async {
    context.reset();
    Uri uri = description.uri;
    String contents = await new File.fromUri(uri).readAsString();
    Map<String, List<String>> sources = <String, List<String>>{};
    List<IncrementalExpectation> expectations;
    bool firstPatch = true;
    YamlMap map = loadYamlNode(contents, sourceUrl: uri);
    map.forEach((_fileName, _contents) {
      String fileName = _fileName; // Strong mode hurray!
      String contents = _contents; // Strong mode hurray!
      if (fileName.endsWith(".patch")) {
        fileName = fileName.substring(0, fileName.length - ".patch".length);
        if (firstPatch) {
          expectations = extractJsonExpectations(contents);
        }
        sources[fileName] = expandUpdates(expandDiff(contents));
        firstPatch = false;
      } else {
        sources[fileName] = <String>[contents];
      }
    });
    final IncrementalKernelGenerator generator =
        await IncrementalKernelGenerator.newInstance(
            null, context.options.inputs.first,
            processedOptions: context.options, useMinimalGenerator: true);
    final TestCase test = new TestCase(description, sources, expectations,
        context.options.fileSystem, generator, context.errors);
    return test.validate(this);
  }
}

class FullCompile extends Step<TestCase, TestCase, Context> {
  String get name => "full compile";

  const FullCompile();

  Future<Result<TestCase>> run(TestCase test, Context context) async {
    test.sources.forEach((String name, List<String> sources) {
      Uri uri = base.resolve(name);
      test.fs.entityForUri(uri).writeAsStringSync(sources.first);
    });
    test.program = (await test.generator.computeDelta()).newProgram;
    List<CompilationMessage> errors = test.takeErrors();
    if (errors.isNotEmpty && !test.expectations.first.hasCompileTimeError) {
      return fail(test, errors.join("\n"));
    } else {
      return pass(test);
    }
  }
}

class IncrementalUpdates extends Step<TestCase, TestCase, Context> {
  const IncrementalUpdates();

  String get name => "incremental updates";

  Future<Result<TestCase>> run(TestCase test, Context context) async {
    return pass(test);
  }
}

class TestCase {
  final TestDescription description;

  final Map<String, List<String>> sources;

  final List<IncrementalExpectation> expectations;

  final MemoryFileSystem fs;

  final IncrementalKernelGenerator generator;

  final List<CompilationMessage> errors;

  Program program;

  TestCase(this.description, this.sources, this.expectations, this.fs,
      this.generator, this.errors);

  String toString() {
    return "TestCase(${json.convert(sources)}, ${json.convert(expectations)})";
  }

  Result<TestCase> validate(Step<dynamic, TestCase, ChainContext> step) {
    print(this);
    if (sources == null) {
      return step.fail(this, "No sources.");
    }
    if (expectations == null || expectations.isEmpty) {
      return step.fail(this, "No expectations.");
    }
    for (String name in sources.keys) {
      List<String> versions = sources[name];
      if (versions.length != 1 && versions.length != expectations.length) {
        return step.fail(
            this,
            "Found ${versions.length} versions of $name,"
            " but expected 1 or ${expectations.length}.");
      }
    }
    return step.pass(this);
  }

  List<CompilationMessage> takeErrors() {
    List<CompilationMessage> result = new List<CompilationMessage>.from(errors);
    errors.clear();
    return result;
  }
}

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  /// The custom URI used to locate the dill file in the MemoryFileSystem.
  final Uri sdkSummary = base.resolve("vm_platform.dill");

  /// The actual location of the dill file.
  final Uri sdkSummaryFile =
      computePlatformBinariesLocation().resolve("vm_platform.dill");

  final MemoryFileSystem fs = new MemoryFileSystem(base);

  fs
      .entityForUri(sdkSummary)
      .writeAsBytesSync(await new File.fromUri(sdkSummaryFile).readAsBytes());

  final List<CompilationMessage> errors = <CompilationMessage>[];

  final CompilerOptions optionBuilder = new CompilerOptions()
    ..strongMode = false
    ..reportMessages = true
    ..verbose = true
    ..fileSystem = fs
    ..sdkSummary = sdkSummary
    ..onError = (CompilationMessage message) {
      if (message.severity != Severity.nit &&
          message.severity != Severity.warning) {
        errors.add(message);
      }
    };

  final ProcessedOptions options =
      new ProcessedOptions(optionBuilder, false, [base.resolve("main.dart")]);

  final ExternalStateSnapshot snapshot =
      new ExternalStateSnapshot(await options.loadSdkSummary(null));

  return new Context(options, snapshot, errors);
}

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, "../../testing.json");
