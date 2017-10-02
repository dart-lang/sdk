// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.tool.command_line;

import 'dart:io' show exit;

import 'package:front_end/compiler_options.dart' show CompilerOptions;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/fasta_codes.dart'
    show
        Message,
        templateFastaCLIArgumentRequired,
        messageFastaUsageLong,
        messageFastaUsageShort,
        templateUnspecified;

import 'package:front_end/src/fasta/problems.dart' show unhandled;

import 'package:front_end/src/fasta/severity.dart' show Severity;

import 'package:kernel/target/targets.dart'
    show Target, getTarget, TargetFlags, targets;

class CommandLineProblem {
  final Message message;

  CommandLineProblem(this.message);

  CommandLineProblem.deprecated(String message)
      : this(templateUnspecified.withArguments(message));
}

class ParsedArguments {
  final Map<String, dynamic> options = <String, dynamic>{};
  final List<String> arguments = <String>[];

  toString() => "ParsedArguments($options, $arguments)";

  /// Parses a list of command-line [arguments] into options and arguments.
  ///
  /// An /option/ is something that, normally, starts with `-` or `--` (one or
  /// two dashes). However, as a special case `/?` and `/h` are also recognized
  /// as options for increased compatibility with Windows. An option can have a
  /// value.
  ///
  /// An /argument/ is something that isn't an option, for example, a file name.
  ///
  /// The specification is a map of options to one of the type literals `Uri`,
  /// `int`, `bool`, or `String`, or a comma (`","`) that represents option
  /// values of type [Uri], [int], [bool], [String], or a comma-separated list
  /// of [String], respectively.
  ///
  /// If [arguments] contains `"--"`, anything before is parsed as options, and
  /// arguments; anything following is treated as arguments (even if starting
  /// with, for example, a `-`).
  ///
  /// Anything that looks like an option is assumed to be a `bool` option set
  /// to true, unless it's mentioned in [specification] in which case the
  /// option requires a value, either on the form `--option value` or
  /// `--option=value`.
  ///
  /// This method performs only a limited amount of validation, but if an error
  /// occurs, it will print [usage] along with a specific error message.
  static ParsedArguments parse(
      List<String> arguments, Map<String, dynamic> specification) {
    specification ??= const <String, dynamic>{};
    ParsedArguments result = new ParsedArguments();
    int index = arguments.indexOf("--");
    Iterable<String> nonOptions = const <String>[];
    Iterator<String> iterator = arguments.iterator;
    if (index != -1) {
      nonOptions = arguments.skip(index + 1);
      iterator = arguments.take(index).iterator;
    }
    while (iterator.moveNext()) {
      String argument = iterator.current;
      if (argument.startsWith("-")) {
        var valueSpecification = specification[argument];
        String value;
        if (valueSpecification != null) {
          if (!iterator.moveNext()) {
            throw new CommandLineProblem(
                templateFastaCLIArgumentRequired.withArguments(argument));
          }
          value = iterator.current;
        } else {
          index = argument.indexOf("=");
          if (index != -1) {
            value = argument.substring(index + 1);
            argument = argument.substring(0, index);
            valueSpecification = specification[argument];
          }
        }
        if (valueSpecification == null) {
          if (value != null) {
            throw new CommandLineProblem.deprecated(
                "Argument '$argument' doesn't take a value: '$value'.");
          }
          result.options[argument] = true;
        } else {
          if (valueSpecification is! String && valueSpecification is! Type) {
            return throw new CommandLineProblem.deprecated(
                "Unrecognized type of value "
                "specification: ${valueSpecification.runtimeType}.");
          }
          switch ("$valueSpecification") {
            case ",":
              result.options
                  .putIfAbsent(argument, () => <String>[])
                  .addAll(value.split(","));
              break;

            case "int":
            case "bool":
            case "String":
            case "Uri":
              if (result.options.containsKey(argument)) {
                return throw new CommandLineProblem.deprecated(
                    "Multiple values for '$argument': "
                    "'${result.options[argument]}' and '$value'.");
              }
              var parsedValue;
              if (valueSpecification == int) {
                parsedValue = int.parse(value, onError: (_) {
                  return throw new CommandLineProblem.deprecated(
                      "Value for '$argument', '$value', isn't an int.");
                });
              } else if (valueSpecification == bool) {
                if (value == "true" || value == "yes") {
                  parsedValue = true;
                } else if (value == "false" || value == "no") {
                  parsedValue = false;
                } else {
                  return throw new CommandLineProblem.deprecated(
                      "Value for '$argument' is '$value', "
                      "but expected one of: 'true', 'false', 'yes', or 'no'.");
                }
              } else if (valueSpecification == Uri) {
                parsedValue = Uri.base.resolve(value);
              } else if (valueSpecification == String) {
                parsedValue = value;
              } else if (valueSpecification is String) {
                return throw new CommandLineProblem.deprecated(
                    "Unrecognized value specification: "
                    "'$valueSpecification', try using a type literal instead.");
              } else {
                // All possible cases should have been handled above.
                return unhandled("${valueSpecification.runtimeType}",
                    "CommandLine.parse", -1, null);
              }
              result.options[argument] = parsedValue;
              break;

            default:
              return throw new CommandLineProblem.deprecated(
                  "Unrecognized value specification: '$valueSpecification'.");
          }
        }
      } else if (argument == "/?" || argument == "/h") {
        result.options[argument] = true;
      } else {
        result.arguments.add(argument);
      }
    }
    result.arguments.addAll(nonOptions);
    return result;
  }
}

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

ProcessedOptions analyzeCommandLine(
    String programName,
    ParsedArguments parsedArguments,
    bool areRestArgumentsInputs,
    bool verbose) {
  final Map<String, dynamic> options = parsedArguments.options;

  final List<String> arguments = parsedArguments.arguments;

  final bool help = options.containsKey("--help") ||
      options.containsKey("-h") ||
      options.containsKey("/h") ||
      options.containsKey("/?");

  if (help) {
    print(computeUsage(programName, verbose).message);
    exit(0);
  }

  if (options.containsKey("-o") && options.containsKey("--output")) {
    return throw new CommandLineProblem.deprecated(
        "Can't specify both '-o' and '--output'.");
  }

  if (options.containsKey("-t") && options.containsKey("--target")) {
    return throw new CommandLineProblem.deprecated(
        "Can't specify both '-t' and '--target'.");
  }

  if (options.containsKey("--compile-sdk") &&
      options.containsKey("--platform")) {
    return throw new CommandLineProblem.deprecated(
        "Can't specify both '--compile-sdk' and '--platform'.");
  }

  if (programName == "compile_platform") {
    if (arguments.length != 3) {
      return throw new CommandLineProblem.deprecated(
          "Expected three arguments.");
    }
    if (options.containsKey("--compile-sdk")) {
      return throw new CommandLineProblem.deprecated(
          "Cannot specify '--compile-sdk' option to compile_platform.");
    }
    options['--compile-sdk'] = Uri.base.resolveUri(new Uri.file(arguments[0]));
  } else if (arguments.isEmpty) {
    return throw new CommandLineProblem.deprecated("No Dart file specified.");
  }

  final bool strongMode = options.containsKey("--strong-mode");

  final String targetName = options["-t"] ?? options["--target"] ?? "vm_fasta";

  final Target target =
      getTarget(targetName, new TargetFlags(strongMode: strongMode));
  if (target == null) {
    return throw new CommandLineProblem.deprecated(
        "Target '${targetName}' not recognized. "
        "Valid targets are:\n  ${targets.keys.join("\n  ")}");
  }

  final bool verify = options.containsKey("--verify");

  final bool dumpIr = options.containsKey("--dump-ir");

  final bool excludeSource = options.containsKey("--exclude-source");

  final Uri defaultOutput = Uri.base.resolve("${arguments.first}.dill");

  final Uri output = options["-o"] ?? options["--output"] ?? defaultOutput;

  final Uri platform = options.containsKey("--compile-sdk")
      ? null
      : options["--platform"] ?? Uri.base.resolve("platform.dill");

  final Uri packages = options["--packages"];

  final Uri sdk = options["--sdk"] ?? options["--compile-sdk"];

  final Set<String> fatal =
      new Set<String>.from(options["--fatal"] ?? <String>[]);

  final bool errorsAreFatal = fatal.contains("errors");

  final bool warningsAreFatal = fatal.contains("warnings");

  final bool nitsAreFatal = fatal.contains("nits");

  CompilerOptions compilerOptions = new CompilerOptions()
    ..compileSdk = options.containsKey("--compile-sdk")
    ..sdkRoot = sdk
    ..sdkSummary = platform
    ..packagesFileUri = packages
    ..strongMode = strongMode
    ..target = target
    ..throwOnErrorsForDebugging = errorsAreFatal
    ..throwOnWarningsForDebugging = warningsAreFatal
    ..throwOnNitsForDebugging = nitsAreFatal
    ..embedSourceText = !excludeSource
    ..debugDump = dumpIr
    ..verbose = verbose
    ..verify = verify;

  // TODO(ahe): What about chase dependencies?

  var inputs = <Uri>[];
  if (areRestArgumentsInputs) {
    inputs = arguments.map(Uri.base.resolve).toList();
  }
  return new ProcessedOptions(compilerOptions, false, inputs, output);
}

dynamic withGlobalOptions(
    String programName,
    List<String> arguments,
    bool areRestArgumentsInputs,
    dynamic f(CompilerContext context, List<String> restArguments)) {
  ParsedArguments parsedArguments;
  ProcessedOptions options;
  bool verbose = true;
  CommandLineProblem problem;
  try {
    parsedArguments = ParsedArguments.parse(arguments, optionSpecification);
    verbose = parsedArguments.options.containsKey("-v") ||
        parsedArguments.options.containsKey("--verbose");
    options = analyzeCommandLine(
        programName, parsedArguments, areRestArgumentsInputs, verbose);
  } on CommandLineProblem catch (e) {
    options = new ProcessedOptions(new CompilerOptions());
    problem = e;
  }

  return CompilerContext.runWithOptions(options, (c) {
    if (problem != null) {
      print(computeUsage(programName, verbose).message);
      print(c.formatWithoutLocation(problem.message, Severity.error));
      exit(1);
    }

    return f(c, parsedArguments.arguments);
  });
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
