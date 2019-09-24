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

import 'package:front_end/src/api_prototype/diagnostic_message.dart'
    show DiagnosticMessage, getMessageCodeObject;

import "package:front_end/src/api_prototype/memory_file_system.dart"
    show MemoryFileSystem;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import 'package:front_end/src/fasta/severity.dart' show Severity;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/kernel.dart'
    show
        Class,
        Component,
        EmptyStatement,
        Field,
        Library,
        LibraryDependency,
        Name,
        Procedure;

import 'package:kernel/target/targets.dart'
    show NoneTarget, Target, TargetFlags;

import 'package:kernel/text/ast_to_text.dart' show componentToString;

import "package:testing/testing.dart"
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import "package:vm/target/vm.dart" show VmTarget;

import "package:yaml/yaml.dart" show YamlList, YamlMap, loadYamlNode;

import 'binary_md_dill_reader.dart' show DillComparer;

import "incremental_utils.dart" as util;

import 'package:front_end/src/fasta/fasta_codes.dart'
    show DiagnosticMessageFromJson, FormattedMessage;

import 'utils/io_utils.dart' show computeRepoDir;

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../testing.json");

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
    Set<String> keys = new Set<String>.from(map.keys.cast<String>());
    keys.remove("type");
    switch (map["type"]) {
      case "basic":
        keys.removeAll(["sources", "entry", "invalidate"]);
        await basicTest(
          map["sources"],
          map["entry"],
          map["invalidate"],
          data.outDir,
        );
        break;
      case "newworld":
        keys.removeAll(["worlds", "modules", "omitPlatform", "target"]);
        await newWorldTest(
          map["worlds"],
          map["modules"],
          map["omitPlatform"],
          map["target"],
        );
        break;
      default:
        throw "Unexpected type: ${map['type']}";
    }

    if (keys.isNotEmpty) throw "Unknown toplevel keys: $keys";
    return pass(data);
  }
}

Future<Null> basicTest(YamlMap sourceFiles, String entryPoint,
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
  CompilerOptions options = getOptions();
  if (packagesUri != null) {
    options.packagesFileUri = packagesUri;
  }
  await normalCompile(entryPointUri, output, options: options);
  print("Normal compile took ${stopwatch.elapsedMilliseconds} ms");

  stopwatch.reset();
  options = getOptions();
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

Future<Map<String, List<int>>> createModules(
    Map module, final List<int> sdkSummaryData, String targetName) async {
  final Uri base = Uri.parse("org-dartlang-test:///");
  final Uri sdkSummary = base.resolve("vm_platform_strong.dill");

  MemoryFileSystem fs = new MemoryFileSystem(base);
  fs.entityForUri(sdkSummary).writeAsBytesSync(sdkSummaryData);

  // Setup all sources
  for (Map moduleSources in module.values) {
    for (String filename in moduleSources.keys) {
      String data = moduleSources[filename];
      Uri uri = base.resolve(filename);
      if (await fs.entityForUri(uri).exists()) {
        throw "More than one entry for $filename";
      }
      fs.entityForUri(uri).writeAsStringSync(data);
    }
  }

  Map<String, List<int>> moduleResult = new Map<String, List<int>>();

  for (String moduleName in module.keys) {
    List<Uri> moduleSources = new List<Uri>();
    Uri packagesUri;
    for (String filename in module[moduleName].keys) {
      Uri uri = base.resolve(filename);
      if (uri.pathSegments.last == ".packages") {
        packagesUri = uri;
      } else {
        moduleSources.add(uri);
      }
    }
    CompilerOptions options = getOptions(targetName: targetName);
    options.fileSystem = fs;
    options.sdkRoot = null;
    options.sdkSummary = sdkSummary;
    options.omitPlatform = true;
    options.onDiagnostic = (DiagnosticMessage message) {
      if (getMessageCodeObject(message)?.name == "InferredPackageUri") return;
      throw message.ansiFormatted;
    };
    if (packagesUri != null) {
      options.packagesFileUri = packagesUri;
    }
    TestIncrementalCompiler compiler =
        new TestIncrementalCompiler(options, moduleSources.first, null);
    Component c = await compiler.computeDelta(entryPoints: moduleSources);
    c.computeCanonicalNames();
    List<Library> wantedLibs = new List<Library>();
    for (Library lib in c.libraries) {
      if (moduleSources.contains(lib.importUri) ||
          moduleSources.contains(lib.fileUri)) {
        wantedLibs.add(lib);
      }
    }
    if (wantedLibs.length != moduleSources.length) {
      throw "Module probably not setup right.";
    }
    Component result = new Component(libraries: wantedLibs);
    List<int> resultBytes = util.postProcess(result);
    moduleResult[moduleName] = resultBytes;
  }

  return moduleResult;
}

Future<Null> newWorldTest(
    List worlds, Map modules, bool omitPlatform, String targetName) async {
  final Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  final Uri base = Uri.parse("org-dartlang-test:///");
  final Uri sdkSummary = base.resolve("vm_platform_strong.dill");
  final Uri initializeFrom = base.resolve("initializeFrom.dill");
  Uri platformUri = sdkRoot.resolve("vm_platform_strong.dill");
  final List<int> sdkSummaryData =
      await new File.fromUri(platformUri).readAsBytes();

  List<int> newestWholeComponentData;
  Component newestWholeComponent;
  MemoryFileSystem fs;
  Map<String, String> sourceFiles;
  CompilerOptions options;
  TestIncrementalCompiler compiler;

  Map<String, List<int>> moduleData;
  Map<String, Component> moduleComponents;
  Component sdk;
  if (modules != null) {
    moduleData = await createModules(modules, sdkSummaryData, targetName);
    sdk = newestWholeComponent = new Component();
    new BinaryBuilder(sdkSummaryData, filename: null, disableLazyReading: false)
        .readComponent(newestWholeComponent);
  }

  int worldNum = 0;
  for (YamlMap world in worlds) {
    worldNum++;
    print("----------------");
    print("World #$worldNum");
    print("----------------");
    List<Component> modulesToUse;
    if (world["modules"] != null) {
      moduleComponents ??= new Map<String, Component>();

      sdk.adoptChildren();
      for (Component c in moduleComponents.values) {
        c.adoptChildren();
      }

      modulesToUse = new List<Component>();
      for (String moduleName in world["modules"]) {
        Component moduleComponent = moduleComponents[moduleName];
        if (moduleComponent != null) {
          modulesToUse.add(moduleComponent);
        }
      }
      for (String moduleName in world["modules"]) {
        Component moduleComponent = moduleComponents[moduleName];
        if (moduleComponent == null) {
          moduleComponent = new Component(nameRoot: sdk.root);
          new BinaryBuilder(moduleData[moduleName],
                  filename: null,
                  disableLazyReading: false,
                  alwaysCreateNewNamedNodes: true)
              .readComponent(moduleComponent);
          moduleComponents[moduleName] = moduleComponent;
          modulesToUse.add(moduleComponent);
        }
      }
    }
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
      options = getOptions(targetName: targetName);
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
    bool outlineOnly = world["outlineOnly"] == true;
    bool skipOutlineBodyCheck = world["skipOutlineBodyCheck"] == true;
    if (brandNewWorld) {
      if (world["fromComponent"] == true) {
        compiler = new TestIncrementalCompiler.fromComponent(
            options, entries.first, newestWholeComponent, outlineOnly);
      } else {
        compiler = new TestIncrementalCompiler(
            options, entries.first, initializeFrom, outlineOnly);
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

    if (modulesToUse != null) {
      compiler.setModulesToLoadOnNextComputeDelta(modulesToUse);
      compiler.invalidateAllSources();
      compiler.trackNeededDillLibraries = true;
    }

    Stopwatch stopwatch = new Stopwatch()..start();
    Component component = await compiler.computeDelta(
        entryPoints: entries,
        fullComponent: brandNewWorld ? false : (noFullComponent ? false : true),
        simulateTransformer: world["simulateTransformer"]);
    if (outlineOnly && !skipOutlineBodyCheck) {
      for (Library lib in component.libraries) {
        for (Class c in lib.classes) {
          for (Procedure p in c.procedures) {
            if (p.function.body != null && p.function.body is! EmptyStatement) {
              throw "Got body (${p.function.body.runtimeType})";
            }
          }
        }
        for (Procedure p in lib.procedures) {
          if (p.function.body != null && p.function.body is! EmptyStatement) {
            throw "Got body (${p.function.body.runtimeType})";
          }
        }
      }
    }
    performErrorAndWarningCheck(
        world, gotError, formattedErrors, gotWarning, formattedWarnings);
    util.throwOnEmptyMixinBodies(component);
    util.throwOnInsufficientUriToSource(component);
    print("Compile took ${stopwatch.elapsedMilliseconds} ms");

    checkExpectedContent(world, component);
    checkNeededDillLibraries(world, compiler.neededDillLibraries, base);

    if (!noFullComponent) {
      Set<Library> allLibraries = new Set<Library>();
      for (Library lib in component.libraries) {
        computeAllReachableLibrariesFor(lib, allLibraries);
      }
      if (allLibraries.length != component.libraries.length) {
        Expect.fail("Expected for the reachable stuff to be equal to "
            "${component.libraries} but it was $allLibraries");
      }
      Set<Library> tooMany = allLibraries.toSet()
        ..removeAll(component.libraries);
      if (tooMany.isNotEmpty) {
        Expect.fail("Expected for the reachable stuff to be equal to "
            "${component.libraries} but these were there too: $tooMany "
            "(and others were missing)");
      }
    }

    newestWholeComponentData = util.postProcess(component);
    newestWholeComponent = component;
    print("*****\n\ncomponent:\n"
        "${componentToStringSdkFiltered(component)}\n\n\n");

    if (world["uriToSourcesDoesntInclude"] != null) {
      for (String filename in world["uriToSourcesDoesntInclude"]) {
        Uri uri = base.resolve(filename);
        if (component.uriToSource[uri] != null) {
          throw "Expected no uriToSource for $uri but found "
              "${component.uriToSource[uri]}";
        }
      }
    }

    int nonSyntheticLibraries = countNonSyntheticLibraries(component);
    int nonSyntheticPlatformLibraries =
        countNonSyntheticPlatformLibraries(component);
    int syntheticLibraries = countSyntheticLibraries(component);
    if (world["expectsPlatform"] == true) {
      if (nonSyntheticPlatformLibraries < 5) {
        throw "Expected to have at least 5 platform libraries "
            "(actually, the entire sdk), "
            "but got $nonSyntheticPlatformLibraries.";
      }
    } else {
      if (nonSyntheticPlatformLibraries != 0) {
        throw "Expected to have 0 platform libraries "
            "but got $nonSyntheticPlatformLibraries.";
      }
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
        throw "Expected the entries to become libraries. "
            "Got ${entryLib.length} libraries for the expected "
            "${entries.length} entries.";
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
          entryPoints: entries,
          fullComponent: true,
          simulateTransformer: world["simulateTransformer"]);
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

    if (world["expressionCompilation"] != null) {
      Uri uri = base.resolve(world["expressionCompilation"]["uri"]);
      String expression = world["expressionCompilation"]["expression"];
      await compiler.compileExpression(expression, {}, [], "debugExpr", uri);
    }
  }
}

void computeAllReachableLibrariesFor(Library lib, Set<Library> allLibraries) {
  Set<Library> libraries = new Set<Library>();
  List<Library> workList = <Library>[];
  allLibraries.add(lib);
  libraries.add(lib);
  workList.add(lib);
  while (workList.isNotEmpty) {
    Library library = workList.removeLast();
    for (LibraryDependency dependency in library.dependencies) {
      if (libraries.add(dependency.targetLibrary)) {
        workList.add(dependency.targetLibrary);
        allLibraries.add(dependency.targetLibrary);
      }
    }
  }
}

void checkExpectedContent(YamlMap world, Component component) {
  if (world["expectedContent"] != null) {
    Map<String, Set<String>> actualContent = new Map<String, Set<String>>();
    for (Library lib in component.libraries) {
      Set<String> libContent =
          actualContent[lib.importUri.toString()] = new Set<String>();
      for (Class c in lib.classes) {
        libContent.add("Class ${c.name}");
      }
      for (Procedure p in lib.procedures) {
        libContent.add("Procedure ${p.name}");
      }
      for (Field f in lib.fields) {
        libContent.add("Field ${f.name}");
      }
    }

    Map expectedContent = world["expectedContent"];

    doThrow() {
      throw "Expected and actual content not the same.\n"
          "Expected $expectedContent.\n"
          "Got $actualContent";
    }

    if (actualContent.length != expectedContent.length) doThrow();
    Set<String> missingKeys = actualContent.keys.toSet()
      ..removeAll(expectedContent.keys);
    if (missingKeys.isNotEmpty) doThrow();
    for (String key in expectedContent.keys) {
      Set<String> expected = new Set<String>.from(expectedContent[key]);
      Set<String> actual = actualContent[key].toSet();
      if (expected.length != actual.length) doThrow();
      actual.removeAll(expected);
      if (actual.isNotEmpty) doThrow();
    }
  }
}

void checkNeededDillLibraries(
    YamlMap world, Set<Library> neededDillLibraries, Uri base) {
  if (world["neededDillLibraries"] != null) {
    List<Uri> actualContent = new List<Uri>();
    for (Library lib in neededDillLibraries) {
      if (lib.importUri.scheme == "dart") continue;
      actualContent.add(lib.importUri);
    }

    List<Uri> expectedContent = new List<Uri>();
    for (String entry in world["neededDillLibraries"]) {
      expectedContent.add(base.resolve(entry));
    }

    doThrow() {
      throw "Expected and actual content not the same.\n"
          "Expected $expectedContent.\n"
          "Got $actualContent";
    }

    if (actualContent.length != expectedContent.length) doThrow();
    Set<Uri> notInExpected =
        actualContent.toSet().difference(expectedContent.toSet());
    Set<Uri> notInActual =
        expectedContent.toSet().difference(actualContent.toSet());
    if (notInExpected.isNotEmpty) doThrow();
    if (notInActual.isNotEmpty) doThrow();
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
      print("Data differs at byte ${i + 1}.");

      StringBuffer message = new StringBuffer();
      message.writeln("Data differs at byte ${i + 1}.");
      message.writeln("");
      message.writeln("Will try to find more useful information:");

      final String repoDir = computeRepoDir();
      File binaryMd = new File("$repoDir/pkg/kernel/binary.md");
      String binaryMdContent = binaryMd.readAsStringSync();

      DillComparer dillComparer = new DillComparer();
      if (dillComparer.compare(a, b, binaryMdContent, message)) {
        message.writeln(
            "Somehow the two different byte-lists compared to the same.");
      }

      Expect.fail(message.toString());
    }
  }
  Expect.equals(a.length, b.length);
}

CompilerOptions getOptions({String targetName}) {
  final Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  Target target = new VmTarget(new TargetFlags());
  if (targetName != null) {
    if (targetName == "None") {
      target = new NoneTarget(new TargetFlags());
    } else if (targetName == "VM") {
      // default.
    } else {
      throw "Unknown target name '$targetName'";
    }
  }
  CompilerOptions options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..target = target
    ..librariesSpecificationUri = Uri.base.resolve("sdk/lib/libraries.json")
    ..omitPlatform = true
    ..onDiagnostic = (DiagnosticMessage message) {
      if (message.severity == Severity.error ||
          message.severity == Severity.warning) {
        Expect.fail(
            "Unexpected error: ${message.plainTextFormatted.join('\n')}");
      }
    }
    ..sdkSummary = sdkRoot.resolve("vm_platform_strong.dill")
    ..environmentDefines = const {};
  return options;
}

Future<bool> normalCompile(Uri input, Uri output,
    {CompilerOptions options}) async {
  options ??= getOptions();
  TestIncrementalCompiler compiler =
      new TestIncrementalCompiler(options, input);
  List<int> bytes =
      await normalCompileToBytes(input, options: options, compiler: compiler);
  new File.fromUri(output).writeAsBytesSync(bytes);
  return compiler.initializedFromDill;
}

Future<List<int>> normalCompileToBytes(Uri input,
    {CompilerOptions options, IncrementalCompiler compiler}) async {
  Component component = await normalCompileToComponent(input,
      options: options, compiler: compiler);
  return util.postProcess(component);
}

Future<Component> normalCompileToComponent(Uri input,
    {CompilerOptions options, IncrementalCompiler compiler}) async {
  Component component =
      await normalCompilePlain(input, options: options, compiler: compiler);
  util.throwOnEmptyMixinBodies(component);
  util.throwOnInsufficientUriToSource(component);
  return component;
}

Future<Component> normalCompilePlain(Uri input,
    {CompilerOptions options, IncrementalCompiler compiler}) async {
  options ??= getOptions();
  compiler ??= new TestIncrementalCompiler(options, input);
  return await compiler.computeDelta();
}

Future<bool> initializedCompile(
    Uri input, Uri output, Uri initializeWith, List<Uri> invalidateUris,
    {CompilerOptions options}) async {
  options ??= getOptions();
  TestIncrementalCompiler compiler =
      new TestIncrementalCompiler(options, input, initializeWith);
  for (Uri invalidateUri in invalidateUris) {
    compiler.invalidate(invalidateUri);
  }
  Component initializedComponent = await compiler.computeDelta();
  util.throwOnEmptyMixinBodies(initializedComponent);
  util.throwOnInsufficientUriToSource(initializedComponent);
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
  util.throwOnInsufficientUriToSource(initializedFullComponent);
  Expect.equals(initializedComponent.libraries.length,
      initializedFullComponent.libraries.length);
  Expect.equals(initializedComponent.uriToSource.length,
      initializedFullComponent.uriToSource.length);

  for (Uri invalidateUri in invalidateUris) {
    compiler.invalidate(invalidateUri);
  }

  Component partialComponent = await compiler.computeDelta();
  util.throwOnEmptyMixinBodies(partialComponent);
  util.throwOnInsufficientUriToSource(partialComponent);
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
  util.throwOnInsufficientUriToSource(emptyComponent);

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
      [Uri initializeFrom, bool outlineOnly])
      : super(
            new CompilerContext(
                new ProcessedOptions(options: options, inputs: [entryPoint])),
            initializeFrom,
            outlineOnly);

  TestIncrementalCompiler.fromComponent(CompilerOptions options,
      this.entryPoint, Component componentToInitializeFrom, [bool outlineOnly])
      : super.fromComponent(
            new CompilerContext(
                new ProcessedOptions(options: options, inputs: [entryPoint])),
            componentToInitializeFrom,
            outlineOnly);

  @override
  void recordInvalidatedImportUrisForTesting(List<Uri> uris) {
    invalidatedImportUrisForTesting = uris.isEmpty ? null : uris.toSet();
  }

  @override
  void recordNonFullComponentForTesting(Component component) {
    // It should at least contain the sdk. Slight smoke test.
    if (!component.libraries
        .map((lib) => lib.importUri.toString())
        .contains("dart:core")) {
      throw "Loaders builder should contain the sdk, "
          "but didn't even contain dart:core.";
    }
  }

  @override
  Future<Component> computeDelta(
      {List<Uri> entryPoints,
      bool fullComponent = false,
      bool simulateTransformer}) async {
    Component result = await super
        .computeDelta(entryPoints: entryPoints, fullComponent: fullComponent);

    // We should at least have the SDK builders available. Slight smoke test.
    if (!dillLoadedData.loader.builders.keys
        .map((uri) => uri.toString())
        .contains("dart:core")) {
      throw "Loaders builder should contain the sdk, "
          "but didn't even contain dart:core.";
    }

    if (simulateTransformer == true) {
      doSimulateTransformer(result);
    }
    return result;
  }
}

void doSimulateTransformer(Component c) {
  for (Library lib in c.libraries) {
    if (lib.fields
        .where((f) => f.name.name == "lalala_SimulateTransformer")
        .toList()
        .isNotEmpty) continue;
    Name fieldName = new Name("lalala_SimulateTransformer");
    Field field = new Field(fieldName,
        isFinal: true,
        reference: lib.reference.canonicalName
            ?.getChildFromFieldWithName(fieldName)
            ?.reference);
    lib.addMember(field);
    for (Class c in lib.classes) {
      if (c.fields
          .where((f) => f.name.name == "lalala_SimulateTransformer")
          .toList()
          .isNotEmpty) continue;
      fieldName = new Name("lalala_SimulateTransformer");
      field = new Field(fieldName,
          isFinal: true,
          reference: c.reference.canonicalName
              ?.getChildFromFieldWithName(fieldName)
              ?.reference);
      c.addMember(field);
    }
  }
}
