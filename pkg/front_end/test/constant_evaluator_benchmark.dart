// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:compiler/src/kernel/dart2js_target.dart' show Dart2jsTarget;

import 'package:dev_compiler/src/kernel/target.dart' show DevCompilerTarget;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;

import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;
import 'package:front_end/src/fasta/kernel/constant_evaluator.dart' as constants
    show EvaluationMode, transformLibraries, ErrorReporter;
import 'package:front_end/src/fasta/kernel/kernel_api.dart';

import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/target/changed_structure_notifier.dart';

import 'package:kernel/target/targets.dart'
    show ConstantsBackend, DiagnosticReporter, Target, TargetFlags;
import 'package:kernel/type_environment.dart';

import "package:vm/target/flutter.dart" show FlutterTarget;

import "package:vm/target/vm.dart" show VmTarget;

import 'incremental_load_from_dill_suite.dart' show getOptions;

import 'package:front_end/src/fasta/kernel/utils.dart' show serializeComponent;

bool tryWithNoEnvironment;
bool verbose = false;
bool skipNonNullEnvironment = false;
bool skipNullEnvironment = false;

void benchmark(Component component, List<Library> libraries) {
  if (tryWithNoEnvironment == null) throw "tryWithNoEnvironment not set";
  KernelTarget target = incrementalCompiler.userCode;
  constants.EvaluationMode evaluationMode =
      target.getConstantEvaluationModeForTesting();

  Uint8List serializedComponent = serializeComponent(component);

  for (int k = 0; k < 3; k++) {
    Map<String, String> environmentDefines = null;
    String environmentDefinesDescription = "null environment";

    for (int j = 0; j < 2; j++) {
      Stopwatch stopwatch = new Stopwatch()..start();
      int iterations = 0;
      int sum = 0;
      for (int i = 0; i < 5; i++) {
        if (!tryWithNoEnvironment && environmentDefines == null) continue;
        if (skipNullEnvironment && environmentDefines == null) continue;
        if (skipNonNullEnvironment && environmentDefines != null) continue;
        stopwatch.reset();
        Component component = new Component();
        BinaryBuilder binaryBuilder = new BinaryBuilder(serializedComponent,
            disableLazyClassReading: true, disableLazyReading: true);
        binaryBuilder.readComponent(component);
        if (verbose) {
          print("Loaded component in ${stopwatch.elapsedMilliseconds} ms");
        }

        stopwatch.reset();
        CoreTypes coreTypes = new CoreTypes(component);
        ConstantsBackend constantsBackend =
            target.backendTarget.constantsBackend(coreTypes);
        ClassHierarchy hierarchy = new ClassHierarchy(component, coreTypes);
        TypeEnvironment environment = new TypeEnvironment(coreTypes, hierarchy);
        if (verbose) {
          print("Created core types and class hierarchy"
              " in ${stopwatch.elapsedMilliseconds} ms");
        }

        stopwatch.reset();
        constants.transformLibraries(
            component.libraries,
            constantsBackend,
            environmentDefines,
            environment,
            new SilentErrorReporter(),
            evaluationMode,
            evaluateAnnotations: true,
            enableTripleShift: target
                .isExperimentEnabledGlobally(ExperimentalFlag.tripleShift),
            errorOnUnevaluatedConstant:
                incrementalCompiler.context.options.errorOnUnevaluatedConstant);
        print("Transformed constants with $environmentDefinesDescription"
            " in ${stopwatch.elapsedMilliseconds} ms");
        sum += stopwatch.elapsedMilliseconds;
        iterations++;
      }
      if (verbose) {
        print("With $environmentDefinesDescription: "
            "Did constant evaluation $iterations iterations in $sum ms,"
            " i.e. an average of ${sum / iterations} ms per iteration.");
      }
      environmentDefines = {};
      environmentDefinesDescription = "empty environment";
    }
  }
}

class SilentErrorReporter implements constants.ErrorReporter {
  @override
  void report(LocatedMessage message, List<LocatedMessage> context) {
    // ignore
  }

  @override
  void reportInvalidExpression(InvalidExpression node) {
    // ignore
  }
}

IncrementalCompiler incrementalCompiler;

main(List<String> arguments) async {
  Uri platformUri;
  Uri mainUri;
  bool nnbd = false;
  String targetString = "VM";

  String filename;
  for (String arg in arguments) {
    if (arg.startsWith("--")) {
      if (arg == "--nnbd") {
        nnbd = true;
      } else if (arg.startsWith("--platform=")) {
        String platform = arg.substring("--platform=".length);
        platformUri = Uri.base.resolve(platform);
      } else if (arg == "--target=VM") {
        targetString = "VM";
      } else if (arg == "--target=flutter") {
        targetString = "flutter";
      } else if (arg == "--target=ddc") {
        targetString = "ddc";
      } else if (arg == "--target=dart2js") {
        targetString = "dart2js";
      } else if (arg == "-v") {
        verbose = true;
      } else if (arg == "--skip-null-environment") {
        skipNullEnvironment = true;
      } else if (arg == "--skip-non-null-environment") {
        skipNonNullEnvironment = true;
      } else {
        throw "Unknown option $arg";
      }
    } else if (filename != null) {
      throw "Already got '$filename', '$arg' is also a filename; "
          "can only get one";
    } else {
      filename = arg;
    }
  }

  if (platformUri == null) {
    throw "No platform given. Use --platform=/path/to/platform.dill";
  }
  if (!new File.fromUri(platformUri).existsSync()) {
    throw "The platform file '$platformUri' doesn't exist";
  }
  if (filename == null) {
    throw "Need file to operate on";
  }
  File file = new File(filename);
  if (!file.existsSync()) throw "File $filename doesn't exist.";
  mainUri = file.absolute.uri;

  incrementalCompiler = new IncrementalCompiler(
      setupCompilerContext(nnbd, targetString, false, platformUri, mainUri));
  await incrementalCompiler.computeDelta();
}

CompilerContext setupCompilerContext(bool nnbd, String targetString,
    bool widgetTransformation, Uri platformUri, Uri mainUri) {
  CompilerOptions options = getOptions();

  if (nnbd) {
    options.explicitExperimentalFlags = {ExperimentalFlag.nonNullable: true};
  }

  TargetFlags targetFlags = new TargetFlags(
      enableNullSafety: nnbd, trackWidgetCreation: widgetTransformation);
  Target target;
  switch (targetString) {
    case "VM":
      target = new HookInVmTarget(targetFlags);
      tryWithNoEnvironment = false;
      break;
    case "flutter":
      target = new HookInFlutterTarget(targetFlags);
      tryWithNoEnvironment = false;
      break;
    case "ddc":
      target = new HookInDevCompilerTarget(targetFlags);
      tryWithNoEnvironment = false;
      break;
    case "dart2js":
      target = new HookInDart2jsTarget("dart2js", targetFlags);
      tryWithNoEnvironment = true;
      break;
    default:
      throw "Unknown target '$targetString'";
  }
  options.target = target;
  options.sdkRoot = null;
  options.sdkSummary = platformUri;
  options.omitPlatform = false;
  options.onDiagnostic = (DiagnosticMessage message) {
    // don't care.
  };

  ProcessedOptions processedOptions =
      new ProcessedOptions(options: options, inputs: [mainUri]);
  CompilerContext compilerContext = new CompilerContext(processedOptions);
  return compilerContext;
}

class HookInVmTarget extends VmTarget {
  HookInVmTarget(TargetFlags flags) : super(flags);

  void performPreConstantEvaluationTransformations(
      Component component,
      CoreTypes coreTypes,
      List<Library> libraries,
      DiagnosticReporter diagnosticReporter,
      {void logger(String msg),
      ChangedStructureNotifier changedStructureNotifier}) {
    super.performPreConstantEvaluationTransformations(
        component, coreTypes, libraries, diagnosticReporter,
        logger: logger, changedStructureNotifier: changedStructureNotifier);
    benchmark(component, libraries);
  }
}

class HookInDart2jsTarget extends Dart2jsTarget {
  HookInDart2jsTarget(String name, TargetFlags flags) : super(name, flags);

  void performPreConstantEvaluationTransformations(
      Component component,
      CoreTypes coreTypes,
      List<Library> libraries,
      DiagnosticReporter diagnosticReporter,
      {void logger(String msg),
      ChangedStructureNotifier changedStructureNotifier}) {
    super.performPreConstantEvaluationTransformations(
        component, coreTypes, libraries, diagnosticReporter,
        logger: logger, changedStructureNotifier: changedStructureNotifier);
    benchmark(component, libraries);
  }
}

class HookInDevCompilerTarget extends DevCompilerTarget {
  HookInDevCompilerTarget(TargetFlags flags) : super(flags);

  void performPreConstantEvaluationTransformations(
      Component component,
      CoreTypes coreTypes,
      List<Library> libraries,
      DiagnosticReporter diagnosticReporter,
      {void logger(String msg),
      ChangedStructureNotifier changedStructureNotifier}) {
    super.performPreConstantEvaluationTransformations(
        component, coreTypes, libraries, diagnosticReporter,
        logger: logger, changedStructureNotifier: changedStructureNotifier);
    benchmark(component, libraries);
  }
}

class HookInFlutterTarget extends FlutterTarget {
  HookInFlutterTarget(TargetFlags flags) : super(flags);

  void performPreConstantEvaluationTransformations(
      Component component,
      CoreTypes coreTypes,
      List<Library> libraries,
      DiagnosticReporter diagnosticReporter,
      {void logger(String msg),
      ChangedStructureNotifier changedStructureNotifier}) {
    super.performPreConstantEvaluationTransformations(
        component, coreTypes, libraries, diagnosticReporter,
        logger: logger, changedStructureNotifier: changedStructureNotifier);
    benchmark(component, libraries);
  }
}
