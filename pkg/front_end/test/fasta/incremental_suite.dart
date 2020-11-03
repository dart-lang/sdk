// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.incremental_test;

import "dart:convert" show JsonEncoder;

import "dart:io" show File;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:front_end/src/api_prototype/experimental_flags.dart';

import "package:kernel/ast.dart" show Component;

import "package:testing/testing.dart"
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import "package:testing/src/log.dart" show splitLines;

import "package:yaml/yaml.dart" show YamlMap, loadYamlNode;

import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions, DiagnosticMessage;

import "package:front_end/src/api_prototype/incremental_kernel_generator.dart"
    show IncrementalKernelGenerator;

import "package:front_end/src/api_prototype/memory_file_system.dart"
    show MemoryFileSystem;

import "package:front_end/src/api_prototype/terminal_color_support.dart"
    show printDiagnosticMessage;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import "incremental_expectations.dart"
    show IncrementalExpectation, extractJsonExpectations;

import "incremental_source_files.dart" show expandDiff, expandUpdates;

const JsonEncoder json = const JsonEncoder.withIndent("  ");

final Uri base = Uri.parse("org-dartlang-test:///");

final Uri entryPoint = base.resolve("main.dart");

class Context extends ChainContext {
  final CompilerContext compilerContext;
  final List<DiagnosticMessage> errors;

  final List<Step> steps = const <Step>[
    const ReadTest(),
    const RunCompilations(),
  ];

  final IncrementalKernelGenerator compiler;

  Context(this.compilerContext, this.errors)
      : compiler = new IncrementalCompiler(compilerContext);

  ProcessedOptions get options => compilerContext.options;

  MemoryFileSystem get fileSystem => options.fileSystem;

  Future<T> runInContext<T>(Future<T> action(CompilerContext c)) {
    return compilerContext.runInContext<T>(action);
  }

  void reset() {
    errors.clear();
  }

  List<DiagnosticMessage> takeErrors() {
    List<DiagnosticMessage> result = new List<DiagnosticMessage>.from(errors);
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
      Component component =
          await compiler.computeDelta(entryPoints: [entryPoint]);
      List<DiagnosticMessage> errors = context.takeErrors();
      if (test.expectations[edits].hasCompileTimeError) {
        if (errors.isEmpty) {
          return fail(test, "Compile-time error expected, but none reported");
        }
      } else if (errors.isNotEmpty) {
        String indentedErrors =
            splitLines(errors.map((e) => e.ansiFormatted.join("\n")).join("\n"))
                .join("  ");
        return fail(test, "Unexpected compile-time errors:\n  $indentedErrors");
      } else if (component.libraries.length < 1) {
        return fail(test, "The compiler detected no changes");
      }
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
  final Uri sdkSummary = base.resolve("vm_platform_strong.dill");

  /// The actual location of the dill file.
  final Uri sdkSummaryFile =
      computePlatformBinariesLocation(forceBuildDir: true)
          .resolve("vm_platform_strong.dill");

  final MemoryFileSystem fs = new MemoryFileSystem(base);

  fs
      .entityForUri(sdkSummary)
      .writeAsBytesSync(await new File.fromUri(sdkSummaryFile).readAsBytes());

  final List<DiagnosticMessage> errors = <DiagnosticMessage>[];

  final CompilerOptions optionBuilder = new CompilerOptions()
    ..verbose = true
    ..fileSystem = fs
    ..sdkSummary = sdkSummary
    ..explicitExperimentalFlags = {ExperimentalFlag.nonNullable: false}
    ..onDiagnostic = (DiagnosticMessage message) {
      printDiagnosticMessage(message, print);
      if (message.severity == Severity.error) {
        errors.add(message);
      }
    };

  final ProcessedOptions options =
      new ProcessedOptions(options: optionBuilder, inputs: [entryPoint]);

  return new Context(new CompilerContext(options), errors);
}

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../../testing.json");
