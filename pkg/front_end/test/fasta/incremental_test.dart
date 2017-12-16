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

import 'package:front_end/src/incremental_kernel_generator_impl.dart'
    show IncrementalKernelGeneratorImpl;

import 'package:front_end/src/minimal_incremental_kernel_generator.dart'
    show MinimalIncrementalKernelGenerator;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/uri_translator.dart' show UriTranslator;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import "incremental_expectations.dart"
    show IncrementalExpectation, extractJsonExpectations;

import "incremental_source_files.dart" show expandDiff, expandUpdates;

const JsonEncoder json = const JsonEncoder.withIndent("  ");

final Uri base = Uri.parse("org-dartlang-test:///");

final Uri entryPoint = base.resolve("main.dart");

enum Generator {
  original,
  minimal,
  fasta,
}

Generator generatorFromString(String string) {
  if (string == null) return Generator.fasta;
  switch (string) {
    case "original":
      return Generator.original;
    case "minimal":
      return Generator.minimal;
    case "fasta":
      return Generator.fasta;
    default:
      throw "Unknown generator: '$string'";
  }
}

class Context extends ChainContext {
  final CompilerContext compilerContext;
  final ExternalStateSnapshot snapshot;
  final List<CompilationMessage> errors;
  final Generator requestedGenerator;

  final List<Step> steps = const <Step>[
    const ReadTest(),
    const PrepareIncrementalKernelGenerator(),
    const RunCompilations(),
  ];

  IncrementalKernelGenerator compiler;

  Context(
      this.compilerContext, this.snapshot, this.errors, this.requestedGenerator)
      : compiler = new IncrementalCompiler(compilerContext);

  ProcessedOptions get options => compilerContext.options;

  MemoryFileSystem get fileSystem => options.fileSystem;

  T runInContext<T>(T action(CompilerContext c)) {
    return compilerContext.runInContext<T>(action);
  }

  void reset() {
    errors.clear();
    snapshot.restore();
  }

  List<CompilationMessage> takeErrors() {
    List<CompilationMessage> result = new List<CompilationMessage>.from(errors);
    errors.clear();
    return result;
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
    final TestCase test = new TestCase(description, sources, expectations);
    return test.validate(this);
  }
}

class PrepareIncrementalKernelGenerator
    extends Step<TestCase, TestCase, Context> {
  String get name => "prepare IKG";

  const PrepareIncrementalKernelGenerator();

  Future<Result<TestCase>> run(TestCase test, Context context) async {
    if (Generator.fasta != context.requestedGenerator) {
      context.compiler = await context
          .runInContext<Future<IncrementalKernelGenerator>>(
              (CompilerContext c) async {
        UriTranslator uriTranslator = await c.options.getUriTranslator();
        List<int> sdkOutlineBytes = await c.options.loadSdkSummaryBytes();
        if (Generator.minimal == context.requestedGenerator) {
          return new MinimalIncrementalKernelGenerator(c.options, uriTranslator,
              sdkOutlineBytes, context.options.inputs.first);
        } else {
          return new IncrementalKernelGeneratorImpl(c.options, uriTranslator,
              sdkOutlineBytes, context.options.inputs.first);
        }
      });
    }
    return pass(test);
  }
}

class RunCompilations extends Step<TestCase, TestCase, Context> {
  const RunCompilations();

  String get name => "run compilations";

  Future<Result<TestCase>> run(TestCase test, Context context) async {
    for (int edits = 0;; edits++) {
      bool foundSources = false;
      test.sources.forEach((String name, List<String> sources) {
        if (edits < sources.length) {
          String source = sources[edits];
          Uri uri = base.resolve(name);
          context.fileSystem.entityForUri(uri).writeAsStringSync(source);
          foundSources = true;
          context.compiler.invalidate(uri);
          if (edits == 0) {
            print("==> $uri <==");
          } else {
            print("==> $uri (edit #$edits) <==");
          }
          print(source.trimRight());
        }
      });
      if (!foundSources) {
        return edits == 0 ? fail(test, "No sources found") : pass(test);
      }
      var compiler = context.compiler;
      var delta = compiler is IncrementalCompiler
          ? (await compiler.computeDelta(entryPoint: entryPoint))
          : (await compiler.computeDelta());
      // ignore: UNUSED_LOCAL_VARIABLE
      Program program = delta.newProgram;
      List<CompilationMessage> errors = context.takeErrors();
      if (errors.isNotEmpty && !test.expectations[edits].hasCompileTimeError) {
        return fail(test, errors.join("\n"));
      }
      context.compiler.acceptLastDelta();
    }
  }
}

class TestCase {
  final TestDescription description;

  final Map<String, List<String>> sources;

  final List<IncrementalExpectation> expectations;

  TestCase(this.description, this.sources, this.expectations);

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
      new ProcessedOptions(optionBuilder, false, [entryPoint]);

  final ExternalStateSnapshot snapshot =
      new ExternalStateSnapshot(await options.loadSdkSummary(null));

  final Generator requestedGenerator =
      generatorFromString(environment["generator"]);

  return new Context(
      new CompilerContext(options), snapshot, errors, requestedGenerator);
}

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, "../../testing.json");
