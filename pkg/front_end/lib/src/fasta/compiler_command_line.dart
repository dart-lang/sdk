// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compiler_command_line;

import 'dart:io' show exit;

import 'command_line.dart' show CommandLine, deprecated_argumentError;

import 'compiler_context.dart' show CompilerContext;

import 'package:kernel/target/targets.dart'
    show Target, getTarget, TargetFlags, targets;

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

  bool get setExitCodeOnProblem {
    return options.containsKey("--set-exit-code-on-problem");
  }

  void validate() {
    if (help) {
      print(computeUsage(programName, verbose));
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
    if (programName == "compile_platform" && arguments.length != 3) {
      return deprecated_argumentError(usage, "Expected three arguments.");
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

  Uri get packages => options["--packages"] ?? Uri.base.resolve(".packages");

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

  static dynamic withGlobalOptions(String programName, List<String> arguments,
      dynamic f(CompilerContext context)) {
    return CompilerContext.withGlobalOptions(
        new CompilerCommandLine(programName, arguments), f);
  }

  static CompilerCommandLine forRootContext() {
    return new CompilerCommandLine("", [""]);
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
