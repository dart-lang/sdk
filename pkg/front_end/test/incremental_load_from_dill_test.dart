// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io' show Directory, File;

import 'package:expect/expect.dart' show Expect;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;

import "package:front_end/src/api_prototype/memory_file_system.dart"
    show MemoryFileSystem;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/fasta_codes.dart' show FormattedMessage;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import 'package:front_end/src/fasta/kernel/utils.dart'
    show writeComponentToFile, serializeComponent;

import 'package:front_end/src/fasta/severity.dart' show Severity;

import 'package:kernel/kernel.dart'
    show Class, EmptyStatement, Library, Procedure, Component;

import "package:testing/testing.dart"
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import "package:yaml/yaml.dart" show YamlMap, loadYamlNode;

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, "../testing.json");

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  return new Context();
}

class Context extends ChainContext {
  final List<Step> steps = const <Step>[
    const ReadTest(),
    const RunCompilations(),
  ];

  @override
  void cleanUp(TestDescription description, Result result) {
    cleanupHelper?.outDir?.deleteSync(recursive: true);
  }

  TestData cleanupHelper;
}

class TestData {
  YamlMap map;
  Directory outDir;
}

class ReadTest extends Step<TestDescription, TestData, Context> {
  const ReadTest();

  String get name => "read test";

  Future<Result<TestData>> run(
      TestDescription description, Context context) async {
    Uri uri = description.uri;
    String contents = await new File.fromUri(uri).readAsString();
    TestData data = new TestData();
    data.map = loadYamlNode(contents, sourceUrl: uri);
    data.outDir =
        Directory.systemTemp.createTempSync("incremental_load_from_dill_test");
    context.cleanupHelper = data;
    return pass(data);
  }
}

class RunCompilations extends Step<TestData, TestData, Context> {
  const RunCompilations();

  String get name => "run compilations";

  Future<Result<TestData>> run(TestData data, Context context) async {
    YamlMap map = data.map;
    switch (map["type"]) {
      case "basic":
        await basicTest(
          map["sources"],
          map["entry"],
          map["strong"],
          map["invalidate"],
          data.outDir,
        );
        break;
      case "newworld":
        await newWorldTest(
          map["strong"],
          map["worlds"],
        );
        break;
      default:
        throw "Unexpected type: ${map['type']}";
    }
    return pass(data);
  }
}

void basicTest(Map<String, String> sourceFiles, String entryPoint, bool strong,
    List<String> invalidate, Directory outDir) async {
  Uri entryPointUri;
  Set<String> invalidateFilenames = invalidate?.toSet() ?? new Set<String>();
  List<Uri> invalidateUris = <Uri>[];
  Uri packagesUri;
  for (String filename in sourceFiles.keys) {
    Uri uri = outDir.uri.resolve(filename);
    if (filename == entryPoint) entryPointUri = uri;
    if (invalidateFilenames.contains(filename)) invalidateUris.add(uri);
    String source = sourceFiles[filename];
    if (filename == ".packages") {
      source = substituteVariables(source, outDir.uri);
      packagesUri = uri;
    }
    new File.fromUri(uri).writeAsStringSync(source);
  }

  Uri output = outDir.uri.resolve("full.dill");
  Uri initializedOutput = outDir.uri.resolve("full_from_initialized.dill");

  Stopwatch stopwatch = new Stopwatch()..start();
  CompilerOptions options = getOptions(strong);
  if (packagesUri != null) {
    options.packagesFileUri = packagesUri;
  }
  await normalCompile(entryPointUri, output, options: options);
  print("Normal compile took ${stopwatch.elapsedMilliseconds} ms");

  stopwatch.reset();
  bool initializedResult = await initializedCompile(
      entryPointUri, initializedOutput, output, invalidateUris,
      options: getOptions(strong));
  print("Initialized compile(s) from ${output.pathSegments.last} "
      "took ${stopwatch.elapsedMilliseconds} ms");
  Expect.isTrue(initializedResult);

  // Compare the two files.
  List<int> normalDillData = new File.fromUri(output).readAsBytesSync();
  List<int> initializedDillData =
      new File.fromUri(initializedOutput).readAsBytesSync();
  checkIsEqual(normalDillData, initializedDillData);
}

void newWorldTest(bool strong, List worlds) async {
  final Uri sdkRoot = computePlatformBinariesLocation();
  final Uri base = Uri.parse("org-dartlang-test:///");
  final Uri sdkSummary = base.resolve("vm_platform.dill");
  final Uri initializeFrom = base.resolve("initializeFrom.dill");
  Uri platformUri;
  if (strong) {
    platformUri = sdkRoot.resolve("vm_platform_strong.dill");
  } else {
    platformUri = sdkRoot.resolve("vm_platform.dill");
  }
  final List<int> sdkSummaryData =
      await new File.fromUri(platformUri).readAsBytes();

  List<int> newestWholeComponent;
  for (var world in worlds) {
    MemoryFileSystem fs = new MemoryFileSystem(base);
    fs.entityForUri(sdkSummary).writeAsBytesSync(sdkSummaryData);
    bool expectInitializeFromDill = false;
    if (newestWholeComponent != null && newestWholeComponent.isNotEmpty) {
      fs.entityForUri(initializeFrom).writeAsBytesSync(newestWholeComponent);
      expectInitializeFromDill = true;
    }
    Map<String, String> sourceFiles = world["sources"];
    Uri packagesUri;
    for (String filename in sourceFiles.keys) {
      String data = sourceFiles[filename] ?? "";
      Uri uri = base.resolve(filename);
      if (filename == ".packages") {
        data = substituteVariables(data, base);
        packagesUri = uri;
      }
      fs.entityForUri(uri).writeAsStringSync(data);
    }

    CompilerOptions options = getOptions(strong);
    options.fileSystem = fs;
    options.sdkRoot = null;
    options.sdkSummary = sdkSummary;
    if (packagesUri != null) {
      options.packagesFileUri = packagesUri;
    }
    bool gotError = false;
    List<String> formattedErrors = <String>[];
    bool gotWarning = false;
    List<String> formattedWarnings = <String>[];

    options.onProblem = (FormattedMessage problem, Severity severity,
        List<FormattedMessage> context) {
      if (severity == Severity.error) {
        gotError = true;
        formattedErrors.add(problem.formatted);
      } else if (severity == Severity.warning) {
        gotWarning = true;
        formattedWarnings.add(problem.formatted);
      }
    };

    Uri entry = base.resolve(world["entry"]);
    TestIncrementalCompiler compiler =
        new TestIncrementalCompiler(options, entry, initializeFrom);

    if (world["invalidate"] != null) {
      for (var filename in world["invalidate"]) {
        compiler.invalidate(base.resolve(filename));
      }
    }

    Stopwatch stopwatch = new Stopwatch()..start();
    Component component = await compiler.computeDelta();
    if (world["errors"] == true && !gotError) {
      throw "Expected error, but didn't get any.";
    } else if (world["errors"] != true && gotError) {
      throw "Got unexpected error(s): $formattedErrors.";
    }
    if (world["warnings"] == true && !gotWarning) {
      throw "Expected warning, but didn't get any.";
    } else if (world["warnings"] != true && gotWarning) {
      throw "Got unexpected warnings(s): $formattedWarnings.";
    }
    throwOnEmptyMixinBodies(component);
    print("Compile took ${stopwatch.elapsedMilliseconds} ms");
    newestWholeComponent = serializeComponent(component);
    if (component.libraries.length != world["expectedLibraryCount"]) {
      throw "Expected ${world["expectedLibraryCount"]} libraries, "
          "got ${component.libraries.length}";
    }
    if (component.libraries[0].importUri != entry) {
      throw "Expected the first library to have uri $entry but was "
          "${component.libraries[0].importUri}";
    }
    if (compiler.initializedFromDill != expectInitializeFromDill) {
      throw "Expected that initializedFromDill would be "
          "$expectInitializeFromDill but was ${compiler.initializedFromDill}";
    }
    if (world["invalidate"] != null) {
      Expect.equals(world["invalidate"].length,
          compiler.invalidatedImportUrisForTesting.length);
      List expectedInvalidatedUri = world["expectedInvalidatedUri"];
      if (expectedInvalidatedUri != null) {
        Expect.setEquals(
            expectedInvalidatedUri
                .map((s) => Uri.parse(substituteVariables(s, base))),
            compiler.invalidatedImportUrisForTesting);
      }
    } else {
      Expect.isNull(compiler.invalidatedImportUrisForTesting);
      Expect.isNull(world["expectedInvalidatedUri"]);
    }
  }
}

void checkIsEqual(List<int> a, List<int> b) {
  int length = a.length;
  if (b.length < length) {
    length = b.length;
  }
  for (int i = 0; i < length; ++i) {
    if (a[i] != b[i]) {
      Expect.fail("Data differs at byte ${i+1}.");
    }
  }
  Expect.equals(a.length, b.length);
}

CompilerOptions getOptions(bool strong) {
  final Uri sdkRoot = computePlatformBinariesLocation();
  var options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..librariesSpecificationUri = Uri.base.resolve("sdk/lib/libraries.json")
    ..onProblem = (FormattedMessage problem, Severity severity,
        List<FormattedMessage> context) {
      if (severity == Severity.error || severity == Severity.warning) {
        Expect.fail("Unexpected error: ${problem.formatted}");
      }
    }
    ..strongMode = strong;
  if (strong) {
    options.sdkSummary = sdkRoot.resolve("vm_platform_strong.dill");
  } else {
    options.sdkSummary = sdkRoot.resolve("vm_platform.dill");
  }
  return options;
}

Future<bool> normalCompile(Uri input, Uri output,
    {CompilerOptions options}) async {
  options ??= getOptions(false);
  TestIncrementalCompiler compiler =
      new TestIncrementalCompiler(options, input);
  Component component = await compiler.computeDelta();
  throwOnEmptyMixinBodies(component);
  await writeComponentToFile(component, output);
  return compiler.initializedFromDill;
}

Future<bool> initializedCompile(
    Uri input, Uri output, Uri initializeWith, List<Uri> invalidateUris,
    {CompilerOptions options}) async {
  options ??= getOptions(false);
  TestIncrementalCompiler compiler =
      new TestIncrementalCompiler(options, input, initializeWith);
  for (Uri invalidateUri in invalidateUris) {
    compiler.invalidate(invalidateUri);
  }
  var initializedComponent = await compiler.computeDelta();
  throwOnEmptyMixinBodies(initializedComponent);
  bool result = compiler.initializedFromDill;
  await writeComponentToFile(initializedComponent, output);

  var initializedComponent2 = await compiler.computeDelta(fullComponent: true);
  throwOnEmptyMixinBodies(initializedComponent2);
  Expect.equals(initializedComponent.libraries.length,
      initializedComponent2.libraries.length);
  Expect.equals(initializedComponent.uriToSource.length,
      initializedComponent2.uriToSource.length);

  for (Uri invalidateUri in invalidateUris) {
    compiler.invalidate(invalidateUri);
  }

  var partialComponent = await compiler.computeDelta();
  throwOnEmptyMixinBodies(partialComponent);
  var emptyComponent = await compiler.computeDelta();
  throwOnEmptyMixinBodies(emptyComponent);

  var fullLibUris =
      initializedComponent.libraries.map((lib) => lib.importUri).toList();
  var partialLibUris =
      partialComponent.libraries.map((lib) => lib.importUri).toList();
  var emptyLibUris =
      emptyComponent.libraries.map((lib) => lib.importUri).toList();

  Expect.isTrue(fullLibUris.length > partialLibUris.length ||
      partialLibUris.length == invalidateUris.length);
  Expect.isTrue(partialLibUris.isNotEmpty || invalidateUris.isEmpty);
  Expect.isTrue(emptyLibUris.isEmpty);

  return result;
}

void throwOnEmptyMixinBodies(Component component) {
  int empty = countEmptyMixinBodies(component);
  if (empty != 0) {
    throw "Expected 0 empty bodies in mixins, but found $empty";
  }
}

int countEmptyMixinBodies(Component component) {
  int empty = 0;
  for (Library lib in component.libraries) {
    for (Class c in lib.classes) {
      if (c.isSyntheticMixinImplementation) {
        for (Procedure p in c.procedures) {
          if (p.function.body is EmptyStatement) {
            empty++;
          }
        }
      }
    }
  }
  return empty;
}

String substituteVariables(String source, Uri base) {
  return source.replaceAll(r"${outDirUri}", "${base}");
}

class TestIncrementalCompiler extends IncrementalCompiler {
  List<Uri> invalidatedImportUrisForTesting;

  TestIncrementalCompiler(CompilerOptions options, Uri entryPoint,
      [Uri initializeFrom])
      : super(
            new CompilerContext(
                new ProcessedOptions(options, false, [entryPoint])),
            initializeFrom);

  @override
  void recordInvalidatedImportUrisForTesting(List<Uri> uris) {
    invalidatedImportUrisForTesting = uris.isEmpty ? null : uris.toList();
  }
}
