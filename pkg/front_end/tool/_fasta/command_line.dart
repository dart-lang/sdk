// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.tool.command_line;

import 'dart:async' show Future;

import 'dart:io' show exit, stderr;

import 'package:build_integration/file_system/single_root.dart'
    show SingleRootFileSystem;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, parseExperimentalFlags;

import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag;

import 'package:front_end/src/api_prototype/file_system.dart' show FileSystem;

import 'package:front_end/src/api_prototype/standard_file_system.dart'
    show StandardFileSystem;

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

import 'package:front_end/src/fasta/problems.dart' show DebugAbort, unhandled;

import 'package:front_end/src/fasta/resolve_input_uri.dart'
    show resolveInputUri;

import 'package:front_end/src/fasta/severity.dart' show Severity;

import 'package:front_end/src/scheme_based_file_system.dart'
    show SchemeBasedFileSystem;

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
  final Map<String, String> defines = <String, String>{};

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
        String value;
        if (argument.startsWith("-D")) {
          value = argument.substring("-D".length);
          argument = "-D";
        } else {
          index = argument.indexOf("=");
          if (index != -1) {
            value = argument.substring(index + 1);
            argument = argument.substring(0, index);
          }
        }
        var valueSpecification = specification[argument];
        if (valueSpecification == null) {
          throw new CommandLineProblem.deprecated(
              "Unknown option '$argument'.");
        }
        String canonicalArgument = argument;
        if (valueSpecification is String &&
            valueSpecification != "," &&
            valueSpecification != "<define>") {
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

          case "<define>":
            int index = value.indexOf('=');
            String name;
            String expression;
            if (index != -1) {
              name = value.substring(0, index);
              expression = value.substring(index + 1);
            } else {
              name = value;
              expression = value;
            }
            result.defines[name] = expression;
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
              parsedValue = int.tryParse(value);
              if (parsedValue == null) {
                return throw new CommandLineProblem.deprecated(
                    "Value for '$argument', '$value', isn't an int.");
              }
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
              // TODO(ahe): resolve Uris lazily, so that schemes provided by
              // other flags can be used for parsed command-line arguments too.
              parsedValue = resolveInputUri(value);
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
  "--bytecode": false,
  "--compile-sdk": Uri,
  "--dump-ir": false,
  "--enable-experiment": ",",
  "--exclude-source": false,
  "--omit-platform": false,
  "--fatal": ",",
  "--help": false,
  "--legacy": "--legacy-mode",
  "--legacy-mode": false,
  "--libraries-json": Uri,
  "--no-defines": false,
  "--output": Uri,
  "--packages": Uri,
  "--platform": Uri,
  "--sdk": Uri,
  "--single-root-base": Uri,
  "--single-root-scheme": String,
  "--supermixin": true,
  "--target": String,
  "--enable-asserts": false,
  "--verbose": false,
  "--verify": false,
  "-D": "<define>",
  "-h": "--help",
  "-o": "--output",
  "-t": "--target",
  "-v": "--verbose",
  "/?": "--help",
  "/h": "--help",
};

void throwCommandLineProblem(String message) {
  throw new CommandLineProblem.deprecated(message);
}

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

  final bool legacyMode = options["--legacy-mode"];

  final String targetName = options["--target"] ?? "vm";

  final TargetFlags flags = new TargetFlags(legacyMode: legacyMode);

  final Target target = getTarget(targetName, flags);
  if (target == null) {
    return throw new CommandLineProblem.deprecated(
        "Target '${targetName}' not recognized. "
        "Valid targets are:\n  ${targets.keys.join("\n  ")}");
  }

  final bool noDefines = options["--no-defines"];

  final bool enableAsserts = options["--enable-asserts"];

  final bool verify = options["--verify"];

  final bool dumpIr = options["--dump-ir"];

  final bool excludeSource = options["--exclude-source"];

  final bool omitPlatform = options["--omit-platform"];

  final Uri packages = options["--packages"];

  final Set<String> fatal =
      new Set<String>.from(options["--fatal"] ?? <String>[]);

  final bool errorsAreFatal = fatal.contains("errors");

  final bool warningsAreFatal = fatal.contains("warnings");

  final bool bytecode = options["--bytecode"];

  final bool compileSdk = options.containsKey("--compile-sdk");

  final String singleRootScheme = options["--single-root-scheme"];
  final Uri singleRootBase = options["--single-root-base"];

  FileSystem fileSystem = StandardFileSystem.instance;
  if (singleRootScheme != null) {
    fileSystem = new SchemeBasedFileSystem({
      'file': fileSystem,
      'data': fileSystem,
      // TODO(askesc): remove also when fixing StandardFileSystem (empty schemes
      // should have been handled elsewhere).
      '': fileSystem,
      singleRootScheme: new SingleRootFileSystem(
          singleRootScheme, singleRootBase, fileSystem),
    });
  }

  Map<ExperimentalFlag, bool> experimentalFlags = parseExperimentalFlags(
      options["--enable-experiment"], throwCommandLineProblem);

  if (programName == "compile_platform") {
    if (arguments.length != 5) {
      return throw new CommandLineProblem.deprecated(
          "Expected five arguments.");
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
        options: new CompilerOptions()
          ..sdkSummary = options["--platform"]
          ..librariesSpecificationUri = resolveInputUri(arguments[1])
          ..setExitCodeOnProblem = true
          ..fileSystem = fileSystem
          ..packagesFileUri = packages
          ..legacyMode = legacyMode
          ..target = target
          ..enableAsserts = enableAsserts
          ..throwOnErrorsForDebugging = errorsAreFatal
          ..throwOnWarningsForDebugging = warningsAreFatal
          ..embedSourceText = !excludeSource
          ..debugDump = dumpIr
          ..omitPlatform = omitPlatform
          ..verbose = verbose
          ..verify = verify
          ..bytecode = bytecode
          ..experimentalFlags = experimentalFlags
          ..environmentDefines = noDefines ? null : parsedArguments.defines,
        inputs: <Uri>[Uri.parse(arguments[0])],
        output: resolveInputUri(arguments[3]));
  } else if (arguments.isEmpty) {
    return throw new CommandLineProblem.deprecated("No Dart file specified.");
  }

  final Uri defaultOutput = resolveInputUri("${arguments.first}.dill");

  final Uri output = options["-o"] ?? options["--output"] ?? defaultOutput;

  final Uri sdk = options["--sdk"] ?? options["--compile-sdk"];

  final Uri platform = compileSdk
      ? null
      : (options["--platform"] ??
          computePlatformBinariesLocation(forceBuildDir: true).resolve(
              legacyMode ? "vm_platform.dill" : "vm_platform_strong.dill"));

  CompilerOptions compilerOptions = new CompilerOptions()
    ..compileSdk = compileSdk
    ..fileSystem = fileSystem
    ..sdkRoot = sdk
    ..sdkSummary = platform
    ..packagesFileUri = packages
    ..legacyMode = legacyMode
    ..target = target
    ..enableAsserts = enableAsserts
    ..throwOnErrorsForDebugging = errorsAreFatal
    ..throwOnWarningsForDebugging = warningsAreFatal
    ..embedSourceText = !excludeSource
    ..debugDump = dumpIr
    ..omitPlatform = omitPlatform
    ..verbose = verbose
    ..verify = verify
    ..experimentalFlags = experimentalFlags
    ..environmentDefines = noDefines ? null : parsedArguments.defines;

  // TODO(ahe): What about chase dependencies?

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
    if (arguments.contains("--strong") &&
        arguments.contains("--target=flutter")) {
      // TODO(ahe): Temporarily ignore option to unbreak flutter build.
      arguments = new List<String>.from(arguments);
      arguments.remove("--strong");
      stderr.writeln("Note: the option '--strong' is deprecated.");
    }
    parsedArguments = ParsedArguments.parse(arguments, optionSpecification);
    options = analyzeCommandLine(
        programName, parsedArguments, areRestArgumentsInputs, verbose);
  } on CommandLineProblem catch (e) {
    options = new ProcessedOptions();
    problem = e;
  }

  return CompilerContext.runWithOptions<T>(options, (c) {
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
    [T failingValue]) async {
  if (CompilerContext.isActive) {
    throw "runProtectedFromAbort should be called from 'main',"
        " that is, outside a compiler context.";
  }
  try {
    return await action();
  } on DebugAbort catch (e) {
    print(e.message.message);

    // DebugAbort should never happen in production code, so we want test.py to
    // treat this as a crash which is signalled by exiting with 255.
    exit(255);
  }
  return failingValue;
}
