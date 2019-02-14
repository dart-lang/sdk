// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io' show File;

import 'package:expect/expect.dart' show Expect;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;

import "package:front_end/src/api_prototype/memory_file_system.dart"
    show MemoryFileSystem;

import 'package:front_end/src/api_prototype/diagnostic_message.dart'
    show DiagnosticMessage, getMessageCodeObject;

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

import 'package:front_end/src/fasta/severity.dart' show Severity;

import 'package:kernel/kernel.dart' show Component;

import 'incremental_load_from_dill_test.dart' show getOptions;

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
  Uri entryPoint;
  Uri platformUri;
  List<int> sdkSummaryData;
  List<DiagnosticMessage> errorMessages;
  List<DiagnosticMessage> warningMessages;
  MemoryFileSystem fs;
  CompilerOptions options;

  compileExpectInitializeFailAndSpecificWarning(
      Code expectedWarningCode, bool writeFileOnCrashReport) async {
    errorMessages.clear();
    warningMessages.clear();
    options.writeFileOnCrashReport = writeFileOnCrashReport;
    DeleteTempFilesIncrementalCompiler compiler =
        new DeleteTempFilesIncrementalCompiler(
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

  initialize() async {
    sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
    base = Uri.parse("org-dartlang-test:///");
    sdkSummary = base.resolve("vm_platform.dill");
    initializeFrom = base.resolve("initializeFrom.dill");
    helperFile = base.resolve("helper.dart");
    entryPoint = base.resolve("small.dart");
    platformUri = sdkRoot.resolve("vm_platform_strong.dill");
    sdkSummaryData = await new File.fromUri(platformUri).readAsBytes();
    errorMessages = <DiagnosticMessage>[];
    warningMessages = <DiagnosticMessage>[];
    fs = new MemoryFileSystem(base);
    options = getOptions(true);

    options.fileSystem = fs;
    options.sdkRoot = null;
    options.sdkSummary = sdkSummary;
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
    fs.entityForUri(entryPoint).writeAsStringSync("""
import "helper.dart" as helper;
main() {
    helper.foo();
}
""");
  }

  Future<Null> test() async {
    IncrementalCompiler compiler = new IncrementalCompiler(
        new CompilerContext(
            new ProcessedOptions(options: options, inputs: [entryPoint])),
        initializeFrom);

    Component componentGood = await compiler.computeDelta();
    List<int> dataGood = serializeComponent(componentGood);
    fs.entityForUri(initializeFrom).writeAsBytesSync(dataGood);

    // Initialize from good dill file should be ok.
    compiler = new IncrementalCompiler(
        new CompilerContext(
            new ProcessedOptions(options: options, inputs: [entryPoint])),
        initializeFrom);
    compiler.invalidate(entryPoint);
    Component component = await compiler.computeDelta();
    if (!compiler.initializedFromDill) {
      Expect.fail(
          "Expected to have sucessfully initialized from dill, but didn't.");
    }
    if (errorMessages.isNotEmpty) {
      Expect.fail("Got unexpected errors: " + joinMessages(errorMessages));
    }
    if (warningMessages.isNotEmpty) {
      Expect.fail("Got unexpected warnings: " + joinMessages(warningMessages));
    }

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
