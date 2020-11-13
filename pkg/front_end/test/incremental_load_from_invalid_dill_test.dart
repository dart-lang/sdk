// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage, getMessageCodeObject;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:expect/expect.dart' show Expect;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;
import 'package:front_end/src/api_prototype/experimental_flags.dart';

import "package:front_end/src/api_prototype/memory_file_system.dart"
    show MemoryFileSystem;
import 'package:front_end/src/api_unstable/bazel_worker.dart';

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/fasta_codes.dart'
    show
        Code,
        codeInitializeFromDillNotSelfContained,
        codeInitializeFromDillNotSelfContainedNoDump,
        codeInitializeFromDillUnknownProblem,
        codeInitializeFromDillUnknownProblemNoDump;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import 'package:front_end/src/fasta/kernel/utils.dart' show serializeComponent;

import 'package:kernel/kernel.dart'
    show Component, Library, NonNullableByDefaultCompiledMode;

import 'incremental_load_from_dill_suite.dart' show getOptions;

Future<Null> main() async {
  Tester tester = new Tester();
  await tester.initialize();
  await tester.test();
}

class Tester {
  Uri sdkRoot;
  Uri base;
  Uri sdkSummary;
  Uri initializeFrom;
  Uri helperFile;
  Uri helper2File;
  Uri entryPoint;
  Uri entryPointImportDartFoo;
  Uri platformUri;
  List<int> sdkSummaryData;
  List<DiagnosticMessage> errorMessages;
  List<DiagnosticMessage> warningMessages;
  MemoryFileSystem fs;
  CompilerOptions options;
  IncrementalCompiler compiler;

  void compileExpectInitializeFailAndSpecificWarning(
      Code expectedWarningCode, bool writeFileOnCrashReport) async {
    errorMessages.clear();
    warningMessages.clear();
    options.writeFileOnCrashReport = writeFileOnCrashReport;
    compiler = new DeleteTempFilesIncrementalCompiler(
        new CompilerContext(
            new ProcessedOptions(options: options, inputs: [entryPoint])),
        initializeFrom);
    await compiler.computeDelta();
    if (compiler.initializedFromDill) {
      Expect.fail("Expected to not be able to initialized from dill, but did.");
    }
    if (errorMessages.isNotEmpty) {
      Expect.fail("Got unexpected errors: " + joinMessages(errorMessages));
    }
    if (warningMessages.length != 1) {
      Expect.fail("Got unexpected errors: Expected one, got this: " +
          joinMessages(warningMessages));
    }
    if (getMessageCodeObject(warningMessages[0]) != expectedWarningCode) {
      Expect.fail("Expected ${expectedWarningCode.name} but got " +
          joinMessages(warningMessages));
    }
  }

  Future<Component> compileExpectOk(
      bool initializedFromDill, Uri compileThis) async {
    errorMessages.clear();
    warningMessages.clear();
    options.writeFileOnCrashReport = false;
    compiler = new DeleteTempFilesIncrementalCompiler(
        new CompilerContext(
            new ProcessedOptions(options: options, inputs: [compileThis])),
        initializeFrom);
    Component component = await compiler.computeDelta();

    if (compiler.initializedFromDill != initializedFromDill) {
      Expect.fail("Expected initializedFromDill to be $initializedFromDill "
          "but was ${compiler.initializedFromDill}");
    }
    if (errorMessages.isNotEmpty) {
      Expect.fail("Got unexpected errors: " + joinMessages(errorMessages));
    }
    if (warningMessages.isNotEmpty) {
      Expect.fail("Got unexpected warnings: " + joinMessages(warningMessages));
    }

    return component;
  }

  initialize() async {
    sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
    base = Uri.parse("org-dartlang-test:///");
    sdkSummary = base.resolve("vm_platform.dill");
    initializeFrom = base.resolve("initializeFrom.dill");
    helperFile = base.resolve("helper.dart");
    helper2File = base.resolve("helper2.dart");
    entryPoint = base.resolve("small.dart");
    entryPointImportDartFoo = base.resolve("small_foo.dart");
    platformUri = sdkRoot.resolve("vm_platform_strong.dill");
    sdkSummaryData = await new File.fromUri(platformUri).readAsBytes();
    errorMessages = <DiagnosticMessage>[];
    warningMessages = <DiagnosticMessage>[];
    fs = new MemoryFileSystem(base);
    options = getOptions();

    options.fileSystem = fs;
    options.sdkRoot = null;
    options.sdkSummary = sdkSummary;
    options.omitPlatform = true;
    options.onDiagnostic = (DiagnosticMessage message) {
      if (message.severity == Severity.error) {
        errorMessages.add(message);
      } else if (message.severity == Severity.warning) {
        warningMessages.add(message);
      }
    };

    fs.entityForUri(sdkSummary).writeAsBytesSync(sdkSummaryData);
    fs.entityForUri(helperFile).writeAsStringSync("""
foo() {
    print("hello from foo");
}
""");
    fs.entityForUri(helper2File).writeAsStringSync("""
foo2() {
    print("hello from foo2");
}
""");
    fs.entityForUri(entryPoint).writeAsStringSync("""
import "helper.dart" as helper;
main() {
    helper.foo();
}
""");
    fs.entityForUri(entryPointImportDartFoo).writeAsStringSync("""
import "dart:foo" as helper;
main() {
    helper.foo2();
}
""");
  }

  Future<Null> test() async {
    compiler = new IncrementalCompiler(
        new CompilerContext(
            new ProcessedOptions(options: options, inputs: [entryPoint])),
        initializeFrom);

    Component componentGood = await compiler.computeDelta();
    List<int> dataGood = serializeComponent(componentGood);
    fs.entityForUri(initializeFrom).writeAsBytesSync(dataGood);

    // Create fake "dart:foo" library.
    options.omitPlatform = false;
    compiler = new IncrementalCompiler(
        new CompilerContext(
            new ProcessedOptions(options: options, inputs: [helper2File])),
        initializeFrom);
    Component componentHelper = await compiler.computeDelta();
    Library helper2Lib = componentHelper.libraries
        .firstWhere((lib) => lib.importUri == helper2File);
    helper2Lib.importUri = new Uri(scheme: "dart", path: "foo");
    List<int> sdkWithDartFoo = serializeComponent(componentHelper);
    options.omitPlatform = true;

    // Compile with our fake sdk with dart:foo should be ok.
    List<int> orgSdkBytes = await fs.entityForUri(sdkSummary).readAsBytes();
    fs.entityForUri(sdkSummary).writeAsBytesSync(sdkWithDartFoo);
    Component component = await compileExpectOk(true, entryPointImportDartFoo);
    fs.entityForUri(sdkSummary).writeAsBytesSync(orgSdkBytes);
    if (component.libraries.length != 1) {
      Expect.fail("Expected 1 library, got ${component.libraries.length}: "
          "${component.libraries}");
    }
    List<int> dataLinkedToSdkWithFoo = serializeComponent(component);

    // Initialize from good dill file should be ok.
    await compileExpectOk(true, entryPoint);

    // Create a partial dill file.
    compiler.invalidate(entryPoint);
    component = await compiler.computeDelta();
    if (component.libraries.length != 1) {
      Expect.fail("Expected 1 library, got ${component.libraries.length}: "
          "${component.libraries}");
    }
    List<int> data = serializeComponent(component);
    fs.entityForUri(initializeFrom).writeAsBytesSync(data);

    // Initializing from partial dill should not be ok.
    await compileExpectInitializeFailAndSpecificWarning(
        codeInitializeFromDillNotSelfContained, true);
    await compileExpectInitializeFailAndSpecificWarning(
        codeInitializeFromDillNotSelfContainedNoDump, false);

    // Create a invalid dill file to load from: Should not be ok.
    data = new List<int>.filled(42, 42);
    fs.entityForUri(initializeFrom).writeAsBytesSync(data);
    await compileExpectInitializeFailAndSpecificWarning(
        codeInitializeFromDillUnknownProblem, true);
    await compileExpectInitializeFailAndSpecificWarning(
        codeInitializeFromDillUnknownProblemNoDump, false);

    // Create a dill with a reference to a non-existing sdk thing:
    // Should be ok (for now), but we shouldn't actually initialize from dill.
    fs.entityForUri(initializeFrom).writeAsBytesSync(dataLinkedToSdkWithFoo);
    await compileExpectOk(false, entryPoint);

    // Try to initialize from a dill which contains mixed compilation modes:
    // Should be ok, but we shouldn't actually initialize from dill.
    List<int> mixedPart1;
    {
      // Create a component that is compiled without NNBD.
      Map<ExperimentalFlag, bool> prevTesting =
          options.defaultExperimentFlagsForTesting;
      options.defaultExperimentFlagsForTesting = {
        ExperimentalFlag.nonNullable: false
      };
      NnbdMode prevNnbd = options.nnbdMode;
      options.nnbdMode = NnbdMode.Weak;
      compiler = new IncrementalCompiler(
          new CompilerContext(
              new ProcessedOptions(options: options, inputs: [helper2File])),
          null);
      Component c = await compiler.computeDelta();
      c.setMainMethodAndMode(
          null, false, NonNullableByDefaultCompiledMode.Weak);
      mixedPart1 = serializeComponent(c);
      options.defaultExperimentFlagsForTesting = prevTesting;
      options.nnbdMode = prevNnbd;
    }

    List<int> mixedPart2;
    {
      // Create a component that is compiled with strong NNBD.
      Map<ExperimentalFlag, bool> prevTesting =
          options.defaultExperimentFlagsForTesting;
      options.defaultExperimentFlagsForTesting = {
        ExperimentalFlag.nonNullable: true
      };
      NnbdMode prevNnbd = options.nnbdMode;
      options.nnbdMode = NnbdMode.Strong;
      compiler = new IncrementalCompiler(
          new CompilerContext(
              new ProcessedOptions(options: options, inputs: [helperFile])),
          null);
      Component c = await compiler.computeDelta();
      c.setMainMethodAndMode(
          null, false, NonNullableByDefaultCompiledMode.Strong);
      mixedPart2 = serializeComponent(c);
      options.defaultExperimentFlagsForTesting = prevTesting;
      options.nnbdMode = prevNnbd;
    }

    // Now mix the two components together and try to initialize from them.
    // We expect the compilation to be OK but that the dill is not actually
    // used to initialize from (as it's invalid because of the mixed mode).
    List<int> mixed = [];
    mixed.addAll(mixedPart1);
    mixed.addAll(mixedPart2);
    fs.entityForUri(initializeFrom).writeAsBytesSync(mixed);
    await compileExpectOk(false, entryPoint);
  }
}

class DeleteTempFilesIncrementalCompiler extends IncrementalCompiler {
  DeleteTempFilesIncrementalCompiler(CompilerContext context,
      [Uri initializeFromDillUri])
      : super(context, initializeFromDillUri);

  void recordTemporaryFileForTesting(Uri uri) {
    File f = new File.fromUri(uri);
    if (f.existsSync()) f.deleteSync();
  }
}

String joinMessages(List<DiagnosticMessage> messages) {
  return messages.map((m) => m.plainTextFormatted.join("\n")).join("\n");
}
