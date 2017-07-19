// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compiler_command_line;

import 'dart:io' show exit;

import 'package:kernel/target/targets.dart'
    show Target, getTarget, TargetFlags, targets;

import '../../compiler_options.dart';
import '../base/processed_options.dart';
import 'command_line.dart' show CommandLine, deprecated_argumentError;

import 'compiler_context.dart' show CompilerContext;

import 'fasta_codes.dart'
    show
        Message,
        messageFastaUsageLong,
        messageFastaUsageShort,
        templateUnspecified;

const Map<String, dynamic> optionSpecification = const <String, dynamic>{
  "--compile-sdk": Uri,
  "--fatal": ",",
  "--output": Uri,
  "-o": Uri,
  "--packages": Uri,
  "--platform": Uri,
  "--sdk": Uri,
  "--target": String,
  "-t": String,
};

/// Parser for options accepted by the `fasta` command-line tools.
// TODO(ahe,sigmund): move this and other tools under pkg/front_end/tool/
class CompilerCommandLine extends CommandLine {
  final String programName;

  CompilerCommandLine(String programName, List<String> arguments)
      : programName = programName,
        super(arguments,
            specification: optionSpecification,
            usage: computeUsage(programName, false));

  bool get verify => options.containsKey("--verify");

  bool get dumpIr => options.containsKey("--dump-ir");

  bool get excludeSource => options.containsKey("--exclude-source");

  bool get help {
    return options.containsKey("--help") ||
        options.containsKey("-h") ||
        options.containsKey("/h") ||
        options.containsKey("/?");
  }

  void validate() {
    if (help) {
      print(computeUsage(programName, verbose).message);
      exit(0);
    }

    if (options.containsKey("-o") && options.containsKey("--output")) {
      return deprecated_argumentError(
          usage, "Can't specify both '-o' and '--output'.");
    }
    if (options.containsKey("-t") && options.containsKey("--target")) {
      return deprecated_argumentError(
          usage, "Can't specify both '-t' and '--target'.");
    }
    if (options.containsKey("--compile-sdk") &&
        options.containsKey("--platform")) {
      return deprecated_argumentError(
          usage, "Can't specify both '--compile-sdk' and '--platform'.");
    }
    if (programName == "compile_platform") {
      if (arguments.length != 3) {
        return deprecated_argumentError(usage, "Expected three arguments.");
      }
      if (options.containsKey("--compile-sdk")) {
        return deprecated_argumentError(usage,
            "Cannot specify '--compile-sdk' option to compile_platform.");
      }
      options['--compile-sdk'] =
          Uri.base.resolveUri(new Uri.file(arguments[0]));
    } else if (arguments.isEmpty) {
      return deprecated_argumentError(usage, "No Dart file specified.");
    }

    Target target =
        getTarget(targetName, new TargetFlags(strongMode: strongMode));
    if (target == null) {
      return deprecated_argumentError(
          usage,
          "Target '${targetName}' not recognized. "
          "Valid targets are:\n  ${targets.keys.join("\n  ")}");
    }
    options["target"] = target;
  }

  Uri get output {
    return options["-o"] ?? options["--output"] ?? defaultOutput;
  }

  Uri get defaultOutput => Uri.base.resolve("${arguments.first}.dill");

  Uri get platform {
    return options.containsKey("--compile-sdk")
        ? null
        : options["--platform"] ?? Uri.base.resolve("platform.dill");
  }

  Uri get packages => options["--packages"];

  Uri get sdk => options["--sdk"] ?? options["--compile-sdk"];

  Set<String> get fatal {
    return new Set<String>.from(options["--fatal"] ?? <String>[]);
  }

  bool get errorsAreFatal => fatal.contains("errors");

  bool get warningsAreFatal => fatal.contains("warnings");

  bool get nitsAreFatal => fatal.contains("nits");

  bool get strongMode => options.containsKey("--strong-mode");

  String get targetName {
    return options["-t"] ?? options["--target"] ?? "vm_fasta";
  }

  Target get target => options["target"];

  static dynamic withGlobalOptions(
      String programName,
      List<String> arguments,
      bool areRestArgumentsInputs,
      dynamic f(CompilerContext context, List<String> restArguments)) {
    // TODO(sigmund,ahe): delete this wrapper by moving validation into the
    // callback. Note that this requires some subtle changes because validate
    // sets some implicit options (like --compile-sdk in compile_platform).
    var cl = CompilerContext.runWithDefaultOptions(
        (_) => new CompilerCommandLine(programName, arguments));
    var options = new CompilerOptions()
      ..compileSdk = cl.options.containsKey("--compile-sdk")
      ..sdkRoot = cl.sdk
      ..sdkSummary = cl.platform
      ..packagesFileUri = cl.packages
      ..strongMode = cl.strongMode
      ..target = cl.target
      ..throwOnErrors = cl.errorsAreFatal
      ..throwOnWarnings = cl.warningsAreFatal
      ..throwOnNits = cl.nitsAreFatal
      ..embedSourceText = !cl.excludeSource
      // All command-line tools take only a single entry point and chase
      // dependencies, and provide a non-zero exit code when errors are found.
      ..chaseDependencies = true
      ..setExitCodeOnProblem = true
      ..debugDump = cl.dumpIr
      ..verbose = cl.verbose
      ..verify = cl.verify;

    var inputs = <Uri>[];
    if (areRestArgumentsInputs) {
      inputs = cl.arguments.map(Uri.base.resolve).toList();
    }
    var pOptions = new ProcessedOptions(options, false, inputs, cl.output);
    return CompilerContext.runWithOptions(pOptions, (c) => f(c, cl.arguments));
  }
}

Message computeUsage(String programName, bool verbose) {
  String basicUsage = "Usage: $programName [options] dartfile\n";
  String summary;
  String options =
      (verbose ? messageFastaUsageLong.message : messageFastaUsageShort.message)
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
      basicUsage = "Usage: $programName [options] patched_sdk fullOutput "
          "outlineOutput\n";
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
