// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.tool.command_line;

import 'dart:io' show exit;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:build_integration/file_system/single_root.dart'
    show SingleRootFileSystem;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, parseExperimentalFlags;
import 'package:front_end/src/api_prototype/compiler_options.dart';

import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag, isExperimentEnabled;

import 'package:front_end/src/api_prototype/file_system.dart' show FileSystem;

import 'package:front_end/src/api_prototype/standard_file_system.dart'
    show StandardFileSystem;
import 'package:front_end/src/base/nnbd_mode.dart';

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/base/command_line_options.dart';

import 'package:front_end/src/fasta/fasta_codes.dart'
    show
        Message,
        templateFastaCLIArgumentRequired,
        messageFastaUsageLong,
        messageFastaUsageShort,
        templateUnspecified;

import 'package:front_end/src/fasta/problems.dart' show DebugAbort;

import 'package:front_end/src/fasta/resolve_input_uri.dart'
    show resolveInputUri;

import 'package:front_end/src/scheme_based_file_system.dart'
    show SchemeBasedFileSystem;

import 'package:kernel/target/targets.dart'
    show LateLowering, Target, getTarget, TargetFlags, targets;

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
      List<String> arguments, Map<String, ValueSpecification> specification) {
    specification ??= const <String, ValueSpecification>{};
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
        ValueSpecification valueSpecification = specification[argument];
        if (valueSpecification == null) {
          throw new CommandLineProblem.deprecated(
              "Unknown option '$argument'.");
        }
        String canonicalArgument = argument;
        if (valueSpecification.alias != null) {
          canonicalArgument = valueSpecification.alias;
          valueSpecification = specification[valueSpecification.alias];
        }
        if (valueSpecification == null) {
          throw new CommandLineProblem.deprecated(
              "Unknown option alias '$canonicalArgument'.");
        }
        final bool requiresValue = valueSpecification.requiresValue;
        if (requiresValue && value == null) {
          if (!iterator.moveNext()) {
            throw new CommandLineProblem(
                templateFastaCLIArgumentRequired.withArguments(argument));
          }
          value = iterator.current;
        }
        valueSpecification.processValue(
            result, canonicalArgument, argument, value);
      } else {
        result.arguments.add(argument);
      }
    }
    specification.forEach((String key, ValueSpecification value) {
      if (value.defaultValue != null) {
        result.options[key] ??= value.defaultValue;
      }
    });
    result.arguments.addAll(nonOptions);
    return result;
  }
}

// Before adding new options here, you must:
//  * Document the option.
//  * Get an explicit approval from the front-end team.
const Map<String, ValueSpecification> optionSpecification =
    const <String, ValueSpecification>{
  Flags.compileSdk: const UriValue(),
  Flags.dumpIr: const BoolValue(false),
  Flags.enableExperiment: const StringListValue(),
  Flags.excludeSource: const BoolValue(false),
  Flags.omitPlatform: const BoolValue(false),
  Flags.fatal: const StringListValue(),
  Flags.fatalSkip: const StringValue(),
  Flags.forceLateLowering: const BoolValue(false),
  Flags.forceStaticFieldLowering: const BoolValue(false),
  Flags.forceNoExplicitGetterCalls: const BoolValue(false),
  Flags.help: const BoolValue(false),
  Flags.librariesJson: const UriValue(),
  Flags.noDefines: const BoolValue(false),
  Flags.output: const UriValue(),
  Flags.packages: const UriValue(),
  Flags.platform: const UriValue(),
  Flags.sdk: const UriValue(),
  Flags.singleRootBase: const UriValue(),
  Flags.singleRootScheme: const StringValue(),
  Flags.nnbdWeakMode: const BoolValue(false),
  Flags.nnbdStrongMode: const BoolValue(false),
  Flags.nnbdAgnosticMode: const BoolValue(false),
  Flags.target: const StringValue(),
  Flags.verbose: const BoolValue(false),
  Flags.verify: const BoolValue(false),
  Flags.verifySkipPlatform: const BoolValue(false),
  Flags.warnOnReachabilityCheck: const BoolValue(false),
  Flags.linkDependencies: const UriListValue(),
  Flags.noDeps: const BoolValue(false),
  "-D": const DefineValue(),
  "-h": const AliasValue(Flags.help),
  "--out": const AliasValue(Flags.output),
  "-o": const AliasValue(Flags.output),
  "-t": const AliasValue(Flags.target),
  "-v": const AliasValue(Flags.verbose),
  "/?": const AliasValue(Flags.help),
  "/h": const AliasValue(Flags.help),
};

void throwCommandLineProblem(String message) {
  throw new CommandLineProblem.deprecated(message);
}

ProcessedOptions analyzeCommandLine(String programName,
    ParsedArguments parsedArguments, bool areRestArgumentsInputs) {
  final Map<String, dynamic> options = parsedArguments.options;

  final List<String> arguments = parsedArguments.arguments;

  final bool help = options[Flags.help];

  final bool verbose = options[Flags.verbose];

  if (help) {
    print(computeUsage(programName, verbose).message);
    exit(0);
  }

  if (options.containsKey(Flags.compileSdk) &&
      options.containsKey(Flags.platform)) {
    return throw new CommandLineProblem.deprecated(
        "Can't specify both '${Flags.compileSdk}' and '${Flags.platform}'.");
  }

  final String targetName = options[Flags.target] ?? "vm";

  Map<ExperimentalFlag, bool> explicitExperimentalFlags =
      parseExperimentalFlags(
          parseExperimentalArguments(options[Flags.enableExperiment]),
          onError: throwCommandLineProblem,
          onWarning: print);

  final TargetFlags flags = new TargetFlags(
      forceLateLoweringsForTesting: options[Flags.forceLateLowering]
          ? LateLowering.all
          : LateLowering.none,
      forceStaticFieldLoweringForTesting:
          options[Flags.forceStaticFieldLowering],
      forceNoExplicitGetterCallsForTesting:
          options[Flags.forceNoExplicitGetterCalls],
      enableNullSafety: isExperimentEnabled(ExperimentalFlag.nonNullable,
          explicitExperimentalFlags: explicitExperimentalFlags));

  final Target target = getTarget(targetName, flags);
  if (target == null) {
    return throw new CommandLineProblem.deprecated(
        "Target '${targetName}' not recognized. "
        "Valid targets are:\n  ${targets.keys.join("\n  ")}");
  }

  final bool noDefines = options[Flags.noDefines];

  final bool noDeps = options[Flags.noDeps];

  final bool verify = options[Flags.verify];

  final bool verifySkipPlatform = options[Flags.verifySkipPlatform];

  final bool dumpIr = options[Flags.dumpIr];

  final bool excludeSource = options[Flags.excludeSource];

  final bool omitPlatform = options[Flags.omitPlatform];

  final Uri packages = options[Flags.packages];

  final Set<String> fatal =
      new Set<String>.from(options[Flags.fatal] ?? <String>[]);

  final bool errorsAreFatal = fatal.contains("errors");

  final bool warningsAreFatal = fatal.contains("warnings");

  final int fatalSkip = int.tryParse(options[Flags.fatalSkip] ?? "0") ?? -1;

  final bool compileSdk = options.containsKey(Flags.compileSdk);

  final String singleRootScheme = options[Flags.singleRootScheme];
  final Uri singleRootBase = options[Flags.singleRootBase];

  final bool nnbdStrongMode = options[Flags.nnbdStrongMode];

  final bool nnbdWeakMode = options[Flags.nnbdWeakMode];

  final bool nnbdAgnosticMode = options[Flags.nnbdAgnosticMode];

  final NnbdMode nnbdMode = nnbdAgnosticMode
      ? NnbdMode.Agnostic
      : (nnbdStrongMode ? NnbdMode.Strong : NnbdMode.Weak);

  final bool warnOnReachabilityCheck = options[Flags.warnOnReachabilityCheck];

  final List<Uri> linkDependencies = options[Flags.linkDependencies] ?? [];

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
          singleRootScheme, singleRootBase, fileSystem),
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
    ..verifySkipPlatform = verifySkipPlatform
    ..explicitExperimentalFlags = explicitExperimentalFlags
    ..environmentDefines = noDefines ? null : parsedArguments.defines
    ..nnbdMode = nnbdMode
    ..additionalDills = linkDependencies
    ..emitDeps = !noDeps
    ..warnOnReachabilityCheck = warnOnReachabilityCheck;

  if (programName == "compile_platform") {
    if (arguments.length != 5) {
      return throw new CommandLineProblem.deprecated(
          "Expected five arguments.");
    }
    if (compileSdk) {
      return throw new CommandLineProblem.deprecated(
          "Cannot specify '${Flags.compileSdk}' option to compile_platform.");
    }
    if (options.containsKey(Flags.output)) {
      return throw new CommandLineProblem.deprecated(
          "Cannot specify '${Flags.output}' option to compile_platform.");
    }

    return new ProcessedOptions(
        options: compilerOptions
          ..sdkSummary = options[Flags.platform]
          ..librariesSpecificationUri = resolveInputUri(arguments[1])
          ..setExitCodeOnProblem = true,
        inputs: <Uri>[Uri.parse(arguments[0])],
        output: resolveInputUri(arguments[3]));
  } else if (arguments.isEmpty) {
    return throw new CommandLineProblem.deprecated("No Dart file specified.");
  }

  final Uri defaultOutput = resolveInputUri("${arguments.first}.dill");

  final Uri output = options[Flags.output] ?? defaultOutput;

  final Uri sdk = options[Flags.sdk] ?? options[Flags.compileSdk];

  final Uri librariesJson = options[Flags.librariesJson];

  String computePlatformDillName() {
    switch (target.name) {
      case 'dartdevc':
        return 'dartdevc.dill';
      case 'dart2js':
        return 'dart2js_platform.dill';
      case 'dart2js_server':
        return 'dart2js_platform.dill';
      case 'vm':
        // TODO(johnniwinther): Stop generating 'vm_platform.dill' and rename
        // 'vm_platform_strong.dill' to 'vm_platform.dill'.
        return "vm_platform_strong.dill";
      case 'none':
        return "vm_platform_strong.dill";
      default:
        throwCommandLineProblem("Target '${target.name}' requires an explicit "
            "'${Flags.platform}' option.");
    }
    return null;
  }

  final Uri platform = compileSdk
      ? null
      : (options[Flags.platform] ??
          computePlatformBinariesLocation(forceBuildDir: true)
              .resolve(computePlatformDillName()));
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
  ParsedArguments parsedArguments;
  ProcessedOptions options;
  CommandLineProblem problem;
  try {
    parsedArguments = ParsedArguments.parse(arguments, optionSpecification);
    options = analyzeCommandLine(
        programName, parsedArguments, areRestArgumentsInputs);
  } on CommandLineProblem catch (e) {
    options = new ProcessedOptions();
    problem = e;
  }

  return CompilerContext.runWithOptions<T>(options, (c) {
    if (problem != null) {
      print(computeUsage(programName, options.verbose).message);
      print(c.formatWithoutLocation(problem.message, Severity.error));
      exit(1);
    }

    return f(c, parsedArguments.arguments);
  }, errorOnMissingInput: problem == null);
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
}

abstract class ValueSpecification {
  const ValueSpecification();

  String get alias => null;

  dynamic get defaultValue => null;

  bool get requiresValue => true;

  void processValue(ParsedArguments result, String canonicalArgument,
      String argument, String value);
}

class AliasValue extends ValueSpecification {
  final String alias;

  const AliasValue(this.alias);

  bool get requiresValue =>
      throw new UnsupportedError("AliasValue.requiresValue");

  void processValue(ParsedArguments result, String canonicalArgument,
      String argument, String value) {
    throw new UnsupportedError("AliasValue.processValue");
  }
}

class UriValue extends ValueSpecification {
  const UriValue();

  void processValue(ParsedArguments result, String canonicalArgument,
      String argument, String value) {
    if (result.options.containsKey(canonicalArgument)) {
      throw new CommandLineProblem.deprecated(
          "Multiple values for '$argument': "
          "'${result.options[canonicalArgument]}' and '$value'.");
    }
    // TODO(ahe): resolve Uris lazily, so that schemes provided by
    // other flags can be used for parsed command-line arguments too.
    result.options[canonicalArgument] = resolveInputUri(value);
  }
}

class StringValue extends ValueSpecification {
  const StringValue();

  void processValue(ParsedArguments result, String canonicalArgument,
      String argument, String value) {
    if (result.options.containsKey(canonicalArgument)) {
      throw new CommandLineProblem.deprecated(
          "Multiple values for '$argument': "
          "'${result.options[canonicalArgument]}' and '$value'.");
    }
    result.options[canonicalArgument] = value;
  }
}

class BoolValue extends ValueSpecification {
  final bool defaultValue;

  const BoolValue(this.defaultValue);

  bool get requiresValue => false;

  void processValue(ParsedArguments result, String canonicalArgument,
      String argument, String value) {
    if (result.options.containsKey(canonicalArgument)) {
      throw new CommandLineProblem.deprecated(
          "Multiple values for '$argument': "
          "'${result.options[canonicalArgument]}' and '$value'.");
    }
    bool parsedValue;
    if (value == null || value == "true" || value == "yes") {
      parsedValue = true;
    } else if (value == "false" || value == "no") {
      parsedValue = false;
    } else {
      throw new CommandLineProblem.deprecated(
          "Value for '$argument' is '$value', "
          "but expected one of: 'true', 'false', 'yes', or 'no'.");
    }
    result.options[canonicalArgument] = parsedValue;
  }
}

class IntValue extends ValueSpecification {
  const IntValue();

  void processValue(ParsedArguments result, String canonicalArgument,
      String argument, String value) {
    if (result.options.containsKey(canonicalArgument)) {
      throw new CommandLineProblem.deprecated(
          "Multiple values for '$argument': "
          "'${result.options[canonicalArgument]}' and '$value'.");
    }
    int parsedValue = int.tryParse(value);
    if (parsedValue == null) {
      throw new CommandLineProblem.deprecated(
          "Value for '$argument', '$value', isn't an int.");
    }
    result.options[canonicalArgument] = parsedValue;
  }
}

class DefineValue extends ValueSpecification {
  const DefineValue();

  void processValue(ParsedArguments result, String canonicalArgument,
      String argument, String value) {
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
  }
}

class StringListValue extends ValueSpecification {
  const StringListValue();

  void processValue(ParsedArguments result, String canonicalArgument,
      String argument, String value) {
    result.options
        .putIfAbsent(canonicalArgument, () => <String>[])
        .addAll(value.split(","));
  }
}

class UriListValue extends ValueSpecification {
  const UriListValue();

  void processValue(ParsedArguments result, String canonicalArgument,
      String argument, String value) {
    result.options
        .putIfAbsent(canonicalArgument, () => <Uri>[])
        .addAll(value.split(",").map(resolveInputUri));
  }
}
