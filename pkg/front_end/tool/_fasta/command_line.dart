// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.tool.command_line;

import 'dart:io' show exit;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:_fe_analyzer_shared/src/util/options.dart';

import 'package:build_integration/file_system/single_root.dart'
    show SingleRootFileSystem;

import 'package:front_end/src/api_prototype/compiler_options.dart';

import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag, isExperimentEnabled;

import 'package:front_end/src/api_prototype/file_system.dart' show FileSystem;

import 'package:front_end/src/api_prototype/standard_file_system.dart'
    show StandardFileSystem;
import 'package:front_end/src/api_prototype/terminal_color_support.dart';
import 'package:front_end/src/base/nnbd_mode.dart';

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation, computePlatformDillName;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/base/command_line_options.dart';

import 'package:front_end/src/fasta/fasta_codes.dart'
    show
        Message,
        PlainAndColorizedString,
        messageFastaUsageLong,
        messageFastaUsageShort,
        templateUnspecified;

import 'package:front_end/src/fasta/problems.dart' show DebugAbort;

import 'package:_fe_analyzer_shared/src/util/resolve_input_uri.dart'
    show resolveInputUri;

import 'package:front_end/src/scheme_based_file_system.dart'
    show SchemeBasedFileSystem;

import 'package:kernel/target/targets.dart'
    show Target, TargetFlags, TestTargetFlags, getTarget, targets;

// Before adding new options here, you must:
//  * Document the option.
//  * Get an explicit approval from the front-end team.
const List<Option> optionSpecification = [
  Options.compileSdk,
  Options.dumpIr,
  Options.enableExperiment,
  Options.enableUnscheduledExperiments,
  Options.excludeSource,
  Options.omitPlatform,
  Options.fatal,
  Options.fatalSkip,
  Options.forceLateLowering,
  Options.forceLateLoweringSentinel,
  Options.forceStaticFieldLowering,
  Options.forceNoExplicitGetterCalls,
  Options.forceConstructorTearOffLowering,
  Options.help,
  Options.librariesJson,
  Options.noDefines,
  Options.output,
  Options.packages,
  Options.platform,
  Options.sdk,
  Options.singleRootBase,
  Options.singleRootScheme,
  Options.nnbdWeakMode,
  Options.nnbdStrongMode,
  Options.nnbdAgnosticMode,
  Options.target,
  Options.verbose,
  Options.verbosity,
  Options.verify,
  Options.skipPlatformVerification,
  Options.warnOnReachabilityCheck,
  Options.linkDependencies,
  Options.noDeps,
  Options.invocationModes,
  Options.defines,
];

void throwCommandLineProblem(String message) {
  throw new CommandLineProblem.deprecated(message);
}

ProcessedOptions analyzeCommandLine(String programName,
    ParsedOptions parsedOptions, bool areRestArgumentsInputs) {
  final List<String> arguments = parsedOptions.arguments;

  final bool help = Options.help.read(parsedOptions);

  final bool verbose = Options.verbose.read(parsedOptions);

  if (help) {
    print(computeUsage(programName, verbose).problemMessage);
    exit(0);
  }

  if (parsedOptions.options.containsKey(Flags.compileSdk) &&
      parsedOptions.options.containsKey(Flags.platform)) {
    return throw new CommandLineProblem.deprecated(
        "Can't specify both '${Flags.compileSdk}' and '${Flags.platform}'.");
  }

  final String targetName = Options.target.read(parsedOptions);

  Map<ExperimentalFlag, bool> explicitExperimentalFlags =
      parseExperimentalFlags(
          parseExperimentalArguments(
              Options.enableExperiment.read(parsedOptions)),
          onError: throwCommandLineProblem,
          onWarning: print);

  final TargetFlags flags = new TestTargetFlags(
      forceLateLoweringsForTesting:
          Options.forceLateLowering.read(parsedOptions),
      forceStaticFieldLoweringForTesting:
          Options.forceStaticFieldLowering.read(parsedOptions),
      forceNoExplicitGetterCallsForTesting:
          Options.forceNoExplicitGetterCalls.read(parsedOptions),
      forceConstructorTearOffLoweringForTesting:
          Options.forceConstructorTearOffLowering.read(parsedOptions),
      forceLateLoweringSentinelForTesting:
          Options.forceLateLoweringSentinel.read(parsedOptions),
      enableNullSafety: isExperimentEnabled(ExperimentalFlag.nonNullable,
          explicitExperimentalFlags: explicitExperimentalFlags));

  final Target? target = getTarget(targetName, flags);
  if (target == null) {
    return throw new CommandLineProblem.deprecated(
        "Target '${targetName}' not recognized. "
        "Valid targets are:\n  ${targets.keys.join("\n  ")}");
  }

  final bool noDefines = Options.noDefines.read(parsedOptions);

  final bool noDeps = Options.noDeps.read(parsedOptions);

  final bool verify = Options.verify.read(parsedOptions);

  final bool skipPlatformVerification =
      Options.skipPlatformVerification.read(parsedOptions);

  final bool dumpIr = Options.dumpIr.read(parsedOptions);

  final bool excludeSource = Options.excludeSource.read(parsedOptions);

  final bool omitPlatform = Options.omitPlatform.read(parsedOptions);

  final Uri? packages = Options.packages.read(parsedOptions);

  final Set<String> fatal =
      new Set<String>.from(Options.fatal.read(parsedOptions) ?? <String>[]);

  final bool errorsAreFatal = fatal.contains("errors");

  final bool warningsAreFatal = fatal.contains("warnings");

  final int fatalSkip =
      int.tryParse(Options.fatalSkip.read(parsedOptions) ?? "0") ?? -1;

  final bool compileSdk = Options.compileSdk.read(parsedOptions) != null;

  final String? singleRootScheme = Options.singleRootScheme.read(parsedOptions);
  final Uri? singleRootBase = Options.singleRootBase.read(parsedOptions);

  final bool nnbdStrongMode = Options.nnbdStrongMode.read(parsedOptions);

  final bool nnbdWeakMode = Options.nnbdWeakMode.read(parsedOptions);

  final bool nnbdAgnosticMode = Options.nnbdAgnosticMode.read(parsedOptions);

  final NnbdMode nnbdMode = nnbdAgnosticMode
      ? NnbdMode.Agnostic
      : (nnbdStrongMode ? NnbdMode.Strong : NnbdMode.Weak);

  final bool enableUnscheduledExperiments =
      Options.enableUnscheduledExperiments.read(parsedOptions);

  final bool warnOnReachabilityCheck =
      Options.warnOnReachabilityCheck.read(parsedOptions);

  final List<Uri> linkDependencies =
      Options.linkDependencies.read(parsedOptions) ?? [];

  final String invocationModes =
      Options.invocationModes.read(parsedOptions) ?? '';

  final String verbosity = Options.verbosity.read(parsedOptions);

  if (nnbdStrongMode && nnbdWeakMode) {
    return throw new CommandLineProblem.deprecated(
        "Can't specify both '${Flags.nnbdStrongMode}' and "
        "'${Flags.nnbdWeakMode}'.");
  }

  if (nnbdStrongMode && nnbdAgnosticMode) {
    return throw new CommandLineProblem.deprecated(
        "Can't specify both '${Flags.nnbdStrongMode}' and "
        "'${Flags.nnbdAgnosticMode}'.");
  }

  if (nnbdWeakMode && nnbdAgnosticMode) {
    return throw new CommandLineProblem.deprecated(
        "Can't specify both '${Flags.nnbdWeakMode}' and "
        "'${Flags.nnbdAgnosticMode}'.");
  }

  FileSystem fileSystem = StandardFileSystem.instance;
  if (singleRootScheme != null) {
    fileSystem = new SchemeBasedFileSystem({
      'file': fileSystem,
      'data': fileSystem,
      // TODO(askesc): remove also when fixing StandardFileSystem (empty schemes
      // should have been handled elsewhere).
      '': fileSystem,
      singleRootScheme: new SingleRootFileSystem(
          singleRootScheme, singleRootBase!, fileSystem),
    });
  }

  CompilerOptions compilerOptions = new CompilerOptions()
    ..compileSdk = compileSdk
    ..fileSystem = fileSystem
    ..packagesFileUri = packages
    ..target = target
    ..throwOnErrorsForDebugging = errorsAreFatal
    ..throwOnWarningsForDebugging = warningsAreFatal
    ..skipForDebugging = fatalSkip
    ..embedSourceText = !excludeSource
    ..debugDump = dumpIr
    ..omitPlatform = omitPlatform
    ..verbose = verbose
    ..verify = verify
    ..skipPlatformVerification = skipPlatformVerification
    ..explicitExperimentalFlags = explicitExperimentalFlags
    ..environmentDefines = noDefines ? null : parsedOptions.defines
    ..nnbdMode = nnbdMode
    ..enableUnscheduledExperiments = enableUnscheduledExperiments
    ..additionalDills = linkDependencies
    ..emitDeps = !noDeps
    ..warnOnReachabilityCheck = warnOnReachabilityCheck
    ..invocationModes = InvocationMode.parseArguments(invocationModes)
    ..verbosity = Verbosity.parseArgument(verbosity);

  if (programName == "compile_platform") {
    if (arguments.length != 5) {
      return throw new CommandLineProblem.deprecated(
          "Expected five arguments.");
    }
    if (compileSdk) {
      return throw new CommandLineProblem.deprecated(
          "Cannot specify '${Flags.compileSdk}' option to compile_platform.");
    }
    if (parsedOptions.options.containsKey(Flags.output)) {
      return throw new CommandLineProblem.deprecated(
          "Cannot specify '${Flags.output}' option to compile_platform.");
    }

    return new ProcessedOptions(
        options: compilerOptions
          ..sdkSummary = Options.platform.read(parsedOptions)
          ..librariesSpecificationUri = resolveInputUri(arguments[1])
          ..setExitCodeOnProblem = true,
        inputs: arguments[0].split(',').map(Uri.parse).toList(),
        output: resolveInputUri(arguments[3]));
  } else if (arguments.isEmpty) {
    return throw new CommandLineProblem.deprecated("No Dart file specified.");
  }

  final Uri defaultOutput = resolveInputUri("${arguments.first}.dill");

  final Uri output = Options.output.read(parsedOptions) ?? defaultOutput;

  final Uri? sdk =
      Options.sdk.read(parsedOptions) ?? Options.compileSdk.read(parsedOptions);

  final Uri? librariesJson = Options.librariesJson.read(parsedOptions);

  final Uri? platform = compileSdk
      ? null
      : (Options.platform.read(parsedOptions) ??
          computePlatformBinariesLocation(forceBuildDir: true)
              .resolve(computePlatformDillName(target, nnbdMode, () {
            throwCommandLineProblem(
                "Target '${target.name}' requires an explicit "
                "'${Flags.platform}' option.");
          })!));
  compilerOptions
    ..sdkRoot = sdk
    ..sdkSummary = platform
    ..librariesSpecificationUri = librariesJson;

  List<Uri> inputs = <Uri>[];
  if (areRestArgumentsInputs) {
    for (String argument in arguments) {
      inputs.add(resolveInputUri(argument));
    }
  }
  return new ProcessedOptions(
      options: compilerOptions, inputs: inputs, output: output);
}

Future<T> withGlobalOptions<T>(
    String programName,
    List<String> arguments,
    bool areRestArgumentsInputs,
    Future<T> f(CompilerContext context, List<String> restArguments)) {
  ParsedOptions? parsedOptions;
  ProcessedOptions options;
  CommandLineProblem? problem;
  try {
    parsedOptions = ParsedOptions.parse(arguments, optionSpecification);
    options =
        analyzeCommandLine(programName, parsedOptions, areRestArgumentsInputs);
  } on CommandLineProblem catch (e) {
    options = new ProcessedOptions();
    problem = e;
  }

  return CompilerContext.runWithOptions<T>(options, (CompilerContext c) {
    if (problem != null) {
      print(computeUsage(programName, options.verbose).problemMessage);
      PlainAndColorizedString formatted =
          c.format(problem.message.withoutLocation(), Severity.error);
      String formattedText;
      if (enableColors) {
        formattedText = formatted.colorized;
      } else {
        formattedText = formatted.plain;
      }
      print(formattedText);
      exit(1);
    }

    return f(c, parsedOptions!.arguments);
  }, errorOnMissingInput: problem == null);
}

Message computeUsage(String programName, bool verbose) {
  String basicUsage = "Usage: $programName [options] dartfile\n";
  String? summary;
  String options = (verbose
          ? messageFastaUsageLong.problemMessage
          : messageFastaUsageShort.problemMessage)
      .trim();
  switch (programName) {
    case "outline":
      summary =
          "Creates an outline of a Dart program in the Dill/Kernel IR format.";
      break;

    case "compile":
      summary = "Compiles a Dart program to the Dill/Kernel IR format.";
      break;

    case "run":
      summary = "Runs a Dart program.";
      break;

    case "compile_platform":
      summary = "Compiles Dart SDK platform to the Dill/Kernel IR format.";
      basicUsage = "Usage: $programName [options]"
          " dart-library-uri libraries.json vm_outline_strong.dill"
          " platform.dill outline.dill\n";
  }
  StringBuffer sb = new StringBuffer(basicUsage);
  if (summary != null) {
    sb.writeln();
    sb.writeln(summary);
    sb.writeln();
  }
  sb.write(options);
  // TODO(ahe): Don't use [templateUnspecified].
  return templateUnspecified.withArguments("$sb");
}

Future<T> runProtectedFromAbort<T>(Future<T> Function() action,
    [T? failingValue]) async {
  if (CompilerContext.isActive) {
    throw "runProtectedFromAbort should be called from 'main',"
        " that is, outside a compiler context.";
  }
  try {
    return await action();
  } on DebugAbort catch (e) {
    print(e.message.problemMessage);

    // DebugAbort should never happen in production code, so we want test.py to
    // treat this as a crash which is signalled by exiting with 255.
    exit(255);
  }
}
