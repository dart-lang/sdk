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
    show CompilerOptions, DiagnosticMessage;

import "package:front_end/src/api_prototype/memory_file_system.dart"
    show MemoryFileSystem;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import 'package:front_end/src/fasta/severity.dart' show Severity;

import 'package:kernel/kernel.dart' show Component, Library;

import 'package:kernel/target/targets.dart' show TargetFlags;

import 'package:kernel/text/ast_to_text.dart' show componentToString;

import "package:testing/testing.dart"
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import "package:vm/target/vm.dart" show VmTarget;

import "package:yaml/yaml.dart" show YamlList, YamlMap, loadYamlNode;

import "incremental_utils.dart" as util;

import 'package:front_end/src/fasta/fasta_codes.dart'
    show DiagnosticMessageFromJson, FormattedMessage;

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
  Future<void> cleanUp(TestDescription description, Result result) async {
    await cleanupHelper?.outDir?.delete(recursive: true);
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
          map["omitPlatform"],
        );
        break;
      default:
        throw "Unexpected type: ${map['type']}";
    }
    return pass(data);
  }
}

Future<Null> basicTest(YamlMap sourceFiles, String entryPoint, bool strong,
    YamlList invalidate, Directory outDir) async {
  Uri entryPointUri = outDir.uri.resolve(entryPoint);
  Set<String> invalidateFilenames =
      invalidate == null ? new Set<String>() : new Set<String>.from(invalidate);
  List<Uri> invalidateUris = <Uri>[];
  Uri packagesUri;
  for (String filename in sourceFiles.keys) {
    Uri uri = outDir.uri.resolve(filename);
    if (invalidateFilenames.contains(filename)) {
      invalidateUris.add(uri);
      invalidateFilenames.remove(filename);
    }
    String source = sourceFiles[filename];
    if (filename == ".packages") {
      packagesUri = uri;
    }
    File file = new File.fromUri(uri);
    await file.parent.create(recursive: true);
    await file.writeAsString(source);
  }
  for (String invalidateFilename in invalidateFilenames) {
    if (invalidateFilename.startsWith('package:')) {
      invalidateUris.add(Uri.parse(invalidateFilename));
    } else {
      throw "Error in test yaml: $invalidateFilename was not recognized.";
    }
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
  options = getOptions(strong);
  if (packagesUri != null) {
    options.packagesFileUri = packagesUri;
  }
  bool initializedResult = await initializedCompile(
      entryPointUri, initializedOutput, output, invalidateUris,
      options: options);
  print("Initialized compile(s) from ${output.pathSegments.last} "
      "took ${stopwatch.elapsedMilliseconds} ms");
  Expect.isTrue(initializedResult);

  // Compare the two files.
  List<int> normalDillData = new File.fromUri(output).readAsBytesSync();
  List<int> initializedDillData =
      new File.fromUri(initializedOutput).readAsBytesSync();
  checkIsEqual(normalDillData, initializedDillData);
}

Future<Null> newWorldTest(bool strong, List worlds, bool omitPlatform) async {
  final Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
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

  List<int> newestWholeComponentData;
  Component newestWholeComponent;
  MemoryFileSystem fs;
  Map<String, String> sourceFiles;
  CompilerOptions options;
  TestIncrementalCompiler compiler;
  for (YamlMap world in worlds) {
    bool brandNewWorld = true;
    if (world["worldType"] == "updated") {
      brandNewWorld = false;
    }
    bool noFullComponent = false;
    if (world["noFullComponent"] == true) {
      noFullComponent = true;
    }

    if (brandNewWorld) {
      fs = new MemoryFileSystem(base);
    }
    fs.entityForUri(sdkSummary).writeAsBytesSync(sdkSummaryData);
    bool expectInitializeFromDill = false;
    if (newestWholeComponentData != null &&
        newestWholeComponentData.isNotEmpty) {
      fs
          .entityForUri(initializeFrom)
          .writeAsBytesSync(newestWholeComponentData);
      expectInitializeFromDill = true;
    }
    if (world["expectInitializeFromDill"] != null) {
      expectInitializeFromDill = world["expectInitializeFromDill"];
    }
    if (brandNewWorld) {
      sourceFiles = new Map<String, String>.from(world["sources"]);
    } else {
      sourceFiles.addAll(
          new Map<String, String>.from(world["sources"] ?? <String, String>{}));
    }
    Uri packagesUri;
    for (String filename in sourceFiles.keys) {
      String data = sourceFiles[filename] ?? "";
      Uri uri = base.resolve(filename);
      if (filename == ".packages") {
        packagesUri = uri;
      }
      fs.entityForUri(uri).writeAsStringSync(data);
    }
    if (world["dotPackagesFile"] != null) {
      packagesUri = base.resolve(world["dotPackagesFile"]);
    }

    if (brandNewWorld) {
      options = getOptions(strong);
      options.fileSystem = fs;
      options.sdkRoot = null;
      options.sdkSummary = sdkSummary;
      options.omitPlatform = omitPlatform != false;
    }
    if (packagesUri != null) {
      options.packagesFileUri = packagesUri;
    }
    bool gotError = false;
    final Set<String> formattedErrors = Set<String>();
    bool gotWarning = false;
    final Set<String> formattedWarnings = Set<String>();

    options.onDiagnostic = (DiagnosticMessage message) {
      String stringId = message.ansiFormatted.join("\n");
      if (message is FormattedMessage) {
        stringId = message.toJsonString();
      } else if (message is DiagnosticMessageFromJson) {
        stringId = message.toJsonString();
      }
      if (message.severity == Severity.error) {
        gotError = true;
        if (!formattedErrors.add(stringId)) {
          Expect.fail("Got the same message twice: ${stringId}");
        }
      } else if (message.severity == Severity.warning) {
        gotWarning = true;
        if (!formattedWarnings.add(stringId)) {
          Expect.fail("Got the same message twice: ${stringId}");
        }
      }
    };

    List<Uri> entries;
    if (world["entry"] is String) {
      entries = [base.resolve(world["entry"])];
    } else {
      entries = new List<Uri>();
      List<dynamic> entryList = world["entry"];
      for (String entry in entryList) {
        entries.add(base.resolve(entry));
      }
    }
    if (brandNewWorld) {
      if (world["fromComponent"] == true) {
        compiler = new TestIncrementalCompiler.fromComponent(
            options, entries.first, newestWholeComponent);
      } else {
        compiler =
            new TestIncrementalCompiler(options, entries.first, initializeFrom);
      }
    }

    List<Uri> invalidated = new List<Uri>();
    if (world["invalidate"] != null) {
      for (String filename in world["invalidate"]) {
        Uri uri = base.resolve(filename);
        invalidated.add(uri);
        compiler.invalidate(uri);
      }
    }

    Stopwatch stopwatch = new Stopwatch()..start();
    Component component = await compiler.computeDelta(
        entryPoints: entries,
        fullComponent:
            brandNewWorld ? false : (noFullComponent ? false : true));
    performErrorAndWarningCheck(
        world, gotError, formattedErrors, gotWarning, formattedWarnings);
    util.throwOnEmptyMixinBodies(component);
    print("Compile took ${stopwatch.elapsedMilliseconds} ms");
    newestWholeComponentData = util.postProcess(component);
    newestWholeComponent = component;
    print("*****\n\ncomponent:\n"
        "${componentToStringSdkFiltered(component)}\n\n\n");

    int nonSyntheticLibraries = countNonSyntheticLibraries(component);
    int nonSyntheticPlatformLibraries =
        countNonSyntheticPlatformLibraries(component);
    int syntheticLibraries = countSyntheticLibraries(component);
    if (world["expectsPlatform"] == true) {
      if (nonSyntheticPlatformLibraries < 5)
        throw "Expected to have at least 5 platform libraries "
            "(actually, the entire sdk), "
            "but got $nonSyntheticPlatformLibraries.";
    } else {
      if (nonSyntheticPlatformLibraries != 0)
        throw "Expected to have 0 platform libraries "
            "but got $nonSyntheticPlatformLibraries.";
    }
    if (world["expectedLibraryCount"] != null) {
      if (nonSyntheticLibraries - nonSyntheticPlatformLibraries !=
          world["expectedLibraryCount"]) {
        throw "Expected ${world["expectedLibraryCount"]} non-synthetic "
            "libraries, got "
            "${nonSyntheticLibraries - nonSyntheticPlatformLibraries} "
            "(not counting platform libraries)";
      }
    }
    if (world["expectedSyntheticLibraryCount"] != null) {
      if (syntheticLibraries != world["expectedSyntheticLibraryCount"]) {
        throw "Expected ${world["expectedSyntheticLibraryCount"]} synthetic "
            "libraries, got ${syntheticLibraries}";
      }
    }
    if (!noFullComponent) {
      List<Library> entryLib = component.libraries
          .where((Library lib) =>
              entries.contains(lib.importUri) || entries.contains(lib.fileUri))
          .toList();
      if (entryLib.length != entries.length) {
        throw "Expected the entries to become libraries. Got ${entryLib.length} "
            "libraries for the expected ${entries.length} entries.";
      }
    }
    if (compiler.initializedFromDill != expectInitializeFromDill) {
      throw "Expected that initializedFromDill would be "
          "$expectInitializeFromDill but was ${compiler.initializedFromDill}";
    }
    if (world["checkInvalidatedFiles"] != false) {
      Set<Uri> filteredInvalidated =
          compiler.getFilteredInvalidatedImportUrisForTesting(invalidated);
      if (world["invalidate"] != null) {
        Expect.equals(
            world["invalidate"].length, filteredInvalidated?.length ?? 0);
        List expectedInvalidatedUri = world["expectedInvalidatedUri"];
        if (expectedInvalidatedUri != null) {
          Expect.setEquals(expectedInvalidatedUri.map((s) => base.resolve(s)),
              filteredInvalidated);
        }
      } else {
        Expect.isNull(filteredInvalidated);
        Expect.isNull(world["expectedInvalidatedUri"]);
      }
    }

    if (!noFullComponent) {
      Set<String> prevFormattedErrors = formattedErrors.toSet();
      Set<String> prevFormattedWarnings = formattedWarnings.toSet();
      gotError = false;
      formattedErrors.clear();
      gotWarning = false;
      formattedWarnings.clear();
      Component component2 = await compiler.computeDelta(
          entryPoints: entries, fullComponent: true);
      performErrorAndWarningCheck(
          world, gotError, formattedErrors, gotWarning, formattedWarnings);
      List<int> thisWholeComponent = util.postProcess(component2);
      print("*****\n\ncomponent2:\n"
          "${componentToStringSdkFiltered(component2)}\n\n\n");
      checkIsEqual(newestWholeComponentData, thisWholeComponent);
      if (prevFormattedErrors.length != formattedErrors.length) {
        Expect.fail("Previously had ${prevFormattedErrors.length} errors, "
            "now had ${formattedErrors.length}.\n\n"
            "Before:\n"
            "${prevFormattedErrors.join("\n")}"
            "\n\n"
            "Now:\n"
            "${formattedErrors.join("\n")}");
      }
      if ((prevFormattedErrors.toSet()..removeAll(formattedErrors))
          .isNotEmpty) {
        Expect.fail("Previously got error messages $prevFormattedErrors, "
            "now had ${formattedErrors}.");
      }
      if (prevFormattedWarnings.length != formattedWarnings.length) {
        Expect.fail("Previously had ${prevFormattedWarnings.length} errors, "
            "now had ${formattedWarnings.length}.");
      }
      if ((prevFormattedWarnings.toSet()..removeAll(formattedWarnings))
          .isNotEmpty) {
        Expect.fail("Previously got error messages $prevFormattedWarnings, "
            "now had ${formattedWarnings}.");
      }
    }
  }
}

String componentToStringSdkFiltered(Component node) {
  Component c = new Component();
  List<Uri> dartUris = new List<Uri>();
  for (Library lib in node.libraries) {
    if (lib.importUri.scheme == "dart") {
      dartUris.add(lib.importUri);
    } else {
      c.libraries.add(lib);
    }
  }

  StringBuffer s = new StringBuffer();
  s.write(componentToString(c));

  if (dartUris.isNotEmpty) {
    s.writeln("");
    s.writeln("And ${dartUris.length} platform libraries:");
    for (Uri uri in dartUris) {
      s.writeln(" - $uri");
    }
  }

  return s.toString();
}

int countNonSyntheticLibraries(Component c) {
  int result = 0;
  for (Library lib in c.libraries) {
    if (!lib.isSynthetic) result++;
  }
  return result;
}

int countNonSyntheticPlatformLibraries(Component c) {
  int result = 0;
  for (Library lib in c.libraries) {
    if (!lib.isSynthetic && lib.importUri.scheme == "dart") result++;
  }
  return result;
}

int countSyntheticLibraries(Component c) {
  int result = 0;
  for (Library lib in c.libraries) {
    if (lib.isSynthetic) result++;
  }
  return result;
}

void performErrorAndWarningCheck(
    YamlMap world,
    bool gotError,
    Set<String> formattedErrors,
    bool gotWarning,
    Set<String> formattedWarnings) {
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
}

void checkIsEqual(List<int> a, List<int> b) {
  int length = a.length;
  if (b.length < length) {
    length = b.length;
  }
  for (int i = 0; i < length; ++i) {
    if (a[i] != b[i]) {
      Expect.fail("Data differs at byte ${i + 1}.");
    }
  }
  Expect.equals(a.length, b.length);
}

CompilerOptions getOptions(bool strong) {
  final Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  CompilerOptions options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..target = new VmTarget(new TargetFlags(legacyMode: !strong))
    ..librariesSpecificationUri = Uri.base.resolve("sdk/lib/libraries.json")
    ..omitPlatform = true
    ..onDiagnostic = (DiagnosticMessage message) {
      if (message.severity == Severity.error ||
          message.severity == Severity.warning) {
        Expect.fail(
            "Unexpected error: ${message.plainTextFormatted.join('\n')}");
      }
    }
    ..legacyMode = !strong;
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
  util.throwOnEmptyMixinBodies(component);
  new File.fromUri(output).writeAsBytesSync(util.postProcess(component));
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
  Component initializedComponent = await compiler.computeDelta();
  util.throwOnEmptyMixinBodies(initializedComponent);
  bool result = compiler.initializedFromDill;
  new File.fromUri(output)
      .writeAsBytesSync(util.postProcess(initializedComponent));
  int actuallyInvalidatedCount = compiler
          .getFilteredInvalidatedImportUrisForTesting(invalidateUris)
          ?.length ??
      0;
  if (result && actuallyInvalidatedCount < invalidateUris.length) {
    Expect.fail("Expected at least ${invalidateUris.length} invalidated uris, "
        "got $actuallyInvalidatedCount");
  }

  Component initializedFullComponent =
      await compiler.computeDelta(fullComponent: true);
  util.throwOnEmptyMixinBodies(initializedFullComponent);
  Expect.equals(initializedComponent.libraries.length,
      initializedFullComponent.libraries.length);
  Expect.equals(initializedComponent.uriToSource.length,
      initializedFullComponent.uriToSource.length);

  for (Uri invalidateUri in invalidateUris) {
    compiler.invalidate(invalidateUri);
  }

  Component partialComponent = await compiler.computeDelta();
  util.throwOnEmptyMixinBodies(partialComponent);
  actuallyInvalidatedCount = (compiler
          .getFilteredInvalidatedImportUrisForTesting(invalidateUris)
          ?.length ??
      0);
  if (actuallyInvalidatedCount < invalidateUris.length) {
    Expect.fail("Expected at least ${invalidateUris.length} invalidated uris, "
        "got $actuallyInvalidatedCount");
  }

  Component emptyComponent = await compiler.computeDelta();
  util.throwOnEmptyMixinBodies(emptyComponent);

  List<Uri> fullLibUris =
      initializedComponent.libraries.map((lib) => lib.importUri).toList();
  List<Uri> partialLibUris =
      partialComponent.libraries.map((lib) => lib.importUri).toList();
  List<Uri> emptyLibUris =
      emptyComponent.libraries.map((lib) => lib.importUri).toList();

  Expect.isTrue(fullLibUris.length > partialLibUris.length ||
      partialLibUris.length == invalidateUris.length);
  Expect.isTrue(partialLibUris.isNotEmpty || invalidateUris.isEmpty);

  Expect.isTrue(emptyLibUris.isEmpty);

  return result;
}

class TestIncrementalCompiler extends IncrementalCompiler {
  Set<Uri> invalidatedImportUrisForTesting;
  final Uri entryPoint;

  /// Filter out the automatically added entryPoint, unless it's explicitly
  /// specified as being invalidated.
  /// Also filter out uris with "nonexisting.dart" in the name as synthetic
  /// libraries are invalidated automatically too.
  /// This is not perfect, but works for what it's currently used for.
  Set<Uri> getFilteredInvalidatedImportUrisForTesting(
      List<Uri> invalidatedUris) {
    if (invalidatedImportUrisForTesting == null) return null;

    Set<String> invalidatedFilenames =
        invalidatedUris.map((uri) => uri.pathSegments.last).toSet();
    Set<Uri> result = new Set<Uri>();
    for (Uri uri in invalidatedImportUrisForTesting) {
      if (uri.pathSegments.last == "nonexisting.dart") continue;
      if (invalidatedFilenames.contains(entryPoint.pathSegments.last) ||
          invalidatedFilenames.contains(uri.pathSegments.last)) result.add(uri);
    }

    return result.isEmpty ? null : result;
  }

  TestIncrementalCompiler(CompilerOptions options, this.entryPoint,
      [Uri initializeFrom])
      : super(
            new CompilerContext(
                new ProcessedOptions(options: options, inputs: [entryPoint])),
            initializeFrom);

  TestIncrementalCompiler.fromComponent(CompilerOptions options,
      this.entryPoint, Component componentToInitializeFrom)
      : super.fromComponent(
            new CompilerContext(
                new ProcessedOptions(options: options, inputs: [entryPoint])),
            componentToInitializeFrom);

  @override
  void recordInvalidatedImportUrisForTesting(List<Uri> uris) {
    invalidatedImportUrisForTesting = uris.isEmpty ? null : uris.toSet();
  }

  @override
  Future<Component> computeDelta(
      {List<Uri> entryPoints, bool fullComponent = false}) async {
    Component result = await super
        .computeDelta(entryPoints: entryPoints, fullComponent: fullComponent);

    // We should at least have the SDK builders available. Slight smoke test.
    if (!dillLoadedData.loader.builders.keys
        .map((uri) => uri.toString())
        .contains("dart:core")) {
      throw "Loaders builder should contain the sdk, "
          "but didn't even contain dart:core.";
    }
    return result;
  }
}
