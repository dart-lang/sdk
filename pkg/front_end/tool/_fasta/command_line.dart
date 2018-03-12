// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.tool.command_line;

import 'dart:io' show exit;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

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

Uri resolveFile(String path) => Uri.base.resolveUri(new Uri.file(path));

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
  /// The specification is a map of options to one of the following values:
  /// * the type literal `Uri`, representing an option value of type [Uri],
  /// * the type literal `int`, representing an option value of type [int],
  /// * the bool literal `false`, representing a boolean option that is turned
  ///   off by default,
  /// * the bool literal `true, representing a boolean option that is turned on
  ///   by default,
  /// * or the string literal `","`, representing a comma-separated list of
  ///   values.
  ///
  /// If [arguments] contains `"--"`, anything before is parsed as options, and
  /// arguments; anything following is treated as arguments (even if starting
  /// with, for example, a `-`).
  ///
  /// If an option isn't found in [specification], an error is thrown.
  ///
  /// Boolean options do not require an option value, but an optional value can
  /// be provided using the forms `--option=value` where `value` can be `true`
  /// or `yes` to turn on the option, or `false` or `no` to turn it off.  If no
  /// option value is specified, a boolean option is turned on.
  ///
  /// All other options require an option value, either on the form `--option
  /// value` or `--option=value`.
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
      if (argument.startsWith("-") || argument == "/?" || argument == "/h") {
        index = argument.indexOf("=");
        String value;
        if (index != -1) {
          value = argument.substring(index + 1);
          argument = argument.substring(0, index);
        }
        var valueSpecification = specification[argument];
        if (valueSpecification == null) {
          throw new CommandLineProblem.deprecated(
              "Unknown option '$argument'.");
        }
        String canonicalArgument = argument;
        if (valueSpecification is String && valueSpecification != ",") {
          canonicalArgument = valueSpecification;
          valueSpecification = specification[valueSpecification];
        }
        if (valueSpecification == true || valueSpecification == false) {
          valueSpecification = bool;
        }
        if (valueSpecification is! String && valueSpecification is! Type) {
          throw new CommandLineProblem.deprecated("Unrecognized type of value "
              "specification: ${valueSpecification.runtimeType}.");
        }
        final bool requiresValue = valueSpecification != bool;
        if (requiresValue && value == null) {
          if (!iterator.moveNext()) {
            throw new CommandLineProblem(
                templateFastaCLIArgumentRequired.withArguments(argument));
          }
          value = iterator.current;
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
            if (result.options.containsKey(canonicalArgument)) {
              return throw new CommandLineProblem.deprecated(
                  "Multiple values for '$argument': "
                  "'${result.options[canonicalArgument]}' and '$value'.");
            }
            var parsedValue;
            if (valueSpecification == int) {
              parsedValue = int.parse(value, onError: (_) {
                return throw new CommandLineProblem.deprecated(
                    "Value for '$argument', '$value', isn't an int.");
              });
            } else if (valueSpecification == bool) {
              if (value == null || value == "true" || value == "yes") {
                parsedValue = true;
              } else if (value == "false" || value == "no") {
                parsedValue = false;
              } else {
                return throw new CommandLineProblem.deprecated(
                    "Value for '$argument' is '$value', "
                    "but expected one of: 'true', 'false', 'yes', or 'no'.");
              }
            } else if (valueSpecification == Uri) {
              parsedValue = resolveFile(value);
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
            result.options[canonicalArgument] = parsedValue;
            break;

          default:
            return throw new CommandLineProblem.deprecated(
                "Unrecognized value specification: '$valueSpecification'.");
        }
      } else {
        result.arguments.add(argument);
      }
    }
    specification.forEach((String key, value) {
      if (value == bool) {
        result.options[key] ??= false;
      } else if (value is bool) {
        result.options[key] ??= value;
      }
    });
    result.arguments.addAll(nonOptions);
    return result;
  }
}

// Before adding new options here, you must:
//  * Document the option.
//  * Get an explicit approval from the front-end team.
const Map<String, dynamic> optionSpecification = const <String, dynamic>{
  "--compile-sdk": Uri,
  "--dump-ir": false,
  "--exclude-source": false,
  "--fatal": ",",
  "--help": false,
  "--legacy": "--legacy-mode",
  "--legacy-mode": true,
  "--libraries-json": Uri,
  "--output": Uri,
  "--packages": Uri,
  "--platform": Uri,
  "--sdk": Uri,
  "--strong": "--strong-mode",
  "--strong-mode": false,
  "--sync-async": false,
  "--target": String,
  "--verbose": false,
  "--verify": false,
  "-h": "--help",
  "-o": "--output",
  "-t": "--target",
  "-v": "--verbose",
  "/?": "--help",
  "/h": "--help",
};

ProcessedOptions analyzeCommandLine(
    String programName,
    ParsedArguments parsedArguments,
    bool areRestArgumentsInputs,
    bool verbose) {
  final Map<String, dynamic> options = parsedArguments.options;

  final List<String> arguments = parsedArguments.arguments;

  final bool help = options["--help"];

  if (help) {
    print(computeUsage(programName, verbose).message);
    exit(0);
  }

  if (options.containsKey("--compile-sdk") &&
      options.containsKey("--platform")) {
    return throw new CommandLineProblem.deprecated(
        "Can't specify both '--compile-sdk' and '--platform'.");
  }

  final bool strongMode = options["--strong-mode"] || !options["--legacy-mode"];

  final bool syncAsync = options["--sync-async"];

  final String targetName = options["--target"] ?? "vm";

  final TargetFlags flags =
      new TargetFlags(strongMode: strongMode, syncAsync: syncAsync);

  final Target target = getTarget(targetName, flags);
  if (target == null) {
    return throw new CommandLineProblem.deprecated(
        "Target '${targetName}' not recognized. "
        "Valid targets are:\n  ${targets.keys.join("\n  ")}");
  }

  final bool verify = options["--verify"];

  final bool dumpIr = options["--dump-ir"];

  final bool excludeSource = options["--exclude-source"];

  final Uri packages = options["--packages"];

  final Set<String> fatal =
      new Set<String>.from(options["--fatal"] ?? <String>[]);

  final bool errorsAreFatal = fatal.contains("errors");

  final bool warningsAreFatal = fatal.contains("warnings");

  final bool nitsAreFatal = fatal.contains("nits");

  final bool compileSdk = options.containsKey("--compile-sdk");

  if (programName == "compile_platform") {
    if (arguments.length != 4) {
      return throw new CommandLineProblem.deprecated(
          "Expected four arguments.");
    }
    if (compileSdk) {
      return throw new CommandLineProblem.deprecated(
          "Cannot specify '--compile-sdk' option to compile_platform.");
    }
    if (options.containsKey("--output")) {
      return throw new CommandLineProblem.deprecated(
          "Cannot specify '--output' option to compile_platform.");
    }

    return new ProcessedOptions(
        new CompilerOptions()
          ..sdkSummary = options["--platform"]
          ..librariesSpecificationUri = resolveFile(arguments[1])
          ..setExitCodeOnProblem = true
          ..chaseDependencies = true
          ..packagesFileUri = packages
          ..strongMode = strongMode
          ..target = target
          ..throwOnErrorsForDebugging = errorsAreFatal
          ..throwOnWarningsForDebugging = warningsAreFatal
          ..throwOnNitsForDebugging = nitsAreFatal
          ..embedSourceText = !excludeSource
          ..debugDump = dumpIr
          ..verbose = verbose
          ..verify = verify,
        false,
        <Uri>[Uri.parse(arguments[0])],
        resolveFile(arguments[2]));
  } else if (arguments.isEmpty) {
    return throw new CommandLineProblem.deprecated("No Dart file specified.");
  }

  final Uri defaultOutput = resolveFile("${arguments.first}.dill");

  final Uri output = options["-o"] ?? options["--output"] ?? defaultOutput;

  final Uri sdk = options["--sdk"] ?? options["--compile-sdk"];

  final Uri platform = compileSdk
      ? null
      : (options["--platform"] ??
          computePlatformBinariesLocation().resolve("vm_platform.dill"));

  CompilerOptions compilerOptions = new CompilerOptions()
    ..compileSdk = compileSdk
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

  List<Uri> inputs = <Uri>[];
  if (areRestArgumentsInputs) {
    for (String argument in arguments) {
      inputs.add(resolveFile(argument));
    }
  }
  return new ProcessedOptions(compilerOptions, false, inputs, output);
}

dynamic withGlobalOptions(
    String programName,
    List<String> arguments,
    bool areRestArgumentsInputs,
    dynamic f(CompilerContext context, List<String> restArguments)) {
  bool verbose = false;
  for (String argument in arguments) {
    if (argument == "--") break;
    if (argument == "-v" || argument == "--verbose") {
      verbose = true;
      break;
    }
  }
  ParsedArguments parsedArguments;
  ProcessedOptions options;
  CommandLineProblem problem;
  try {
    parsedArguments = ParsedArguments.parse(arguments, optionSpecification);
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
      basicUsage = "Usage: $programName [options]"
          " dart-library-uri libraries.json platform.dill outline.dill\n";
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
