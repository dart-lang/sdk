// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.command_line.arguments;

import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:args/args.dart';
import 'package:path/path.dart';

const String analysisOptionsFileOption = 'options';
const String bazelAnalysisOptionsPath =
    'package:dart.analysis_options/default.yaml';
const String declarationCastsFlag = 'declaration-casts';
const String defineVariableOption = 'D';
const String enableInitializingFormalAccessFlag = 'initializing-formal-access';
const String enableSuperMixinFlag = 'supermixin';
const String flutterAnalysisOptionsPath =
    'package:flutter/analysis_options_user.yaml';
const String ignoreUnrecognizedFlagsFlag = 'ignore-unrecognized-flags';
const String implicitCastsFlag = 'implicit-casts';
const String lintsFlag = 'lints';
const String noImplicitDynamicFlag = 'no-implicit-dynamic';
const String packageDefaultAnalysisOptions = 'package-default-analysis-options';
const String packageRootOption = 'package-root';
const String packagesOption = 'packages';
const String sdkPathOption = 'dart-sdk';

const String sdkSummaryPathOption = 'dart-sdk-summary';
const String strongModeFlag = 'strong';

/**
 * Update [options] with the value of each analysis option command line flag.
 */
void applyAnalysisOptionFlags(AnalysisOptionsImpl options, ArgResults args,
    {void verbosePrint(String text)}) {
  void verbose(String text) {
    if (verbosePrint != null) {
      verbosePrint('Analysis options: $text');
    }
  }

  if (args.wasParsed(enableSuperMixinFlag)) {
    options.enableSuperMixins = args[enableSuperMixinFlag];
    verbose('$enableSuperMixinFlag = ${options.enableSuperMixins}');
  }
  if (args.wasParsed(implicitCastsFlag)) {
    options.implicitCasts = args[implicitCastsFlag];
    verbose('$implicitCastsFlag = ${options.implicitCasts}');
  }
  if (args.wasParsed(declarationCastsFlag)) {
    options.declarationCasts = args[declarationCastsFlag];
    verbose('$declarationCastsFlag = ${options.declarationCasts}');
  } else if (args.wasParsed(implicitCastsFlag)) {
    options.declarationCasts = args[implicitCastsFlag];
    verbose('$declarationCastsFlag = ${options.declarationCasts}');
  }
  if (args.wasParsed(noImplicitDynamicFlag)) {
    options.implicitDynamic = !args[noImplicitDynamicFlag];
    verbose('$noImplicitDynamicFlag = ${options.implicitDynamic}');
  }
  if (args.wasParsed(strongModeFlag)) {
    options.strongMode = args[strongModeFlag];
    verbose('$strongModeFlag = ${options.strongMode}');
  }
  try {
    if (args.wasParsed(lintsFlag)) {
      options.lint = args[lintsFlag];
      verbose('$lintsFlag = ${options.lint}');
    }
  } on ArgumentError {
    // lints were not defined - ignore and fall through
  }
}

/**
 * Use the given [resourceProvider], [contentCache] and command-line [args] to
 * create a context builder.
 */
ContextBuilderOptions createContextBuilderOptions(ArgResults args,
    {bool strongMode, bool trackCacheDependencies}) {
  ContextBuilderOptions builderOptions = new ContextBuilderOptions();
  builderOptions.argResults = args;
  //
  // File locations.
  //
  builderOptions.dartSdkSummaryPath = args[sdkSummaryPathOption];
  builderOptions.defaultAnalysisOptionsFilePath =
      args[analysisOptionsFileOption];
  builderOptions.defaultPackageFilePath = args[packagesOption];
  builderOptions.defaultPackagesDirectoryPath = args[packageRootOption];
  //
  // Flags.
  //
  builderOptions.packageDefaultAnalysisOptions =
      args[packageDefaultAnalysisOptions];
  //
  // Analysis options.
  //
  AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
  applyAnalysisOptionFlags(defaultOptions, args);
  if (strongMode != null) {
    defaultOptions.strongMode = strongMode;
  }
  if (trackCacheDependencies != null) {
    defaultOptions.trackCacheDependencies = trackCacheDependencies;
  }
  builderOptions.defaultOptions = defaultOptions;
  //
  // Declared variables.
  //
  Map<String, String> declaredVariables = <String, String>{};
  List<String> variables = (args[defineVariableOption] as List).cast<String>();
  for (String variable in variables) {
    int index = variable.indexOf('=');
    if (index < 0) {
      // TODO (brianwilkerson) Decide the semantics we want in this case.
      // The VM prints "No value given to -D option", then tries to load '-Dfoo'
      // as a file and dies. Unless there was nothing after the '-D', in which
      // case it prints the warning and ignores the option.
    } else {
      String name = variable.substring(0, index);
      if (name.isNotEmpty) {
        // TODO (brianwilkerson) Decide the semantics we want in the case where
        // there is no name. If there is no name, the VM tries to load a file
        // named '-D' and dies.
        declaredVariables[name] = variable.substring(index + 1);
      }
    }
  }
  builderOptions.declaredVariables = declaredVariables;

  return builderOptions;
}

/**
 * Use the given [resourceProvider] and command-line [args] to create a Dart SDK
 * manager. The manager will use summary information if [useSummaries] is `true`
 * and if the summary information exists.
 */
DartSdkManager createDartSdkManager(
    ResourceProvider resourceProvider, bool useSummaries, ArgResults args) {
  String sdkPath = args[sdkPathOption];

  bool canUseSummaries = useSummaries &&
      args.rest.every((String sourcePath) {
        sourcePath = context.absolute(sourcePath);
        sourcePath = context.normalize(sourcePath);
        return !context.isWithin(sdkPath, sourcePath);
      });
  return new DartSdkManager(
      sdkPath ?? FolderBasedDartSdk.defaultSdkDirectory(resourceProvider),
      canUseSummaries);
}

/**
 * Add the standard flags and options to the given [parser]. The standard flags
 * are those that are typically used to control the way in which the code is
 * analyzed.
 *
 * TODO(danrubel) Update DDC to support all the options defined in this method
 * then remove the [ddc] named argument from this method.
 */
void defineAnalysisArguments(ArgParser parser, {bool hide: true, ddc: false}) {
  parser.addOption(sdkPathOption,
      help: 'The path to the Dart SDK.', hide: ddc && hide);
  parser.addOption(analysisOptionsFileOption,
      help: 'Path to an analysis options file.', hide: ddc && hide);
  parser.addOption(packageRootOption,
      help: 'The path to a package root directory (deprecated). '
          'This option cannot be used with --packages.',
      hide: ddc && hide);
  parser.addFlag(strongModeFlag,
      help: 'Enable strong static checks (https://goo.gl/DqcBsw).',
      defaultsTo: ddc,
      hide: ddc);
  parser.addFlag(declarationCastsFlag,
      negatable: true,
      help: 'Disable declaration casts in strong mode (https://goo.gl/cTLz40).',
      hide: ddc && hide);
  parser.addFlag(implicitCastsFlag,
      negatable: true,
      help: 'Disable implicit casts in strong mode (https://goo.gl/cTLz40).',
      hide: ddc && hide);
  parser.addFlag(noImplicitDynamicFlag,
      negatable: false,
      help: 'Disable implicit dynamic (https://goo.gl/m0UgXD).',
      hide: ddc && hide);

  //
  // Hidden flags and options.
  //
  parser.addMultiOption(defineVariableOption,
      abbr: 'D',
      help: 'Define environment variables. For example, "-Dfoo=bar" defines an '
          'environment variable named "foo" whose value is "bar".',
      hide: hide);
  parser.addFlag(packageDefaultAnalysisOptions,
      help: 'If an analysis options file is not explicitly specified '
          'via the "--$analysisOptionsFileOption" option\n'
          'and an analysis options file cannot be found '
          'in the project directory or any parent directory,\n'
          'then look for analysis options in the following locations:\n'
          '- $flutterAnalysisOptionsPath\n'
          '- $bazelAnalysisOptionsPath',
      defaultsTo: true,
      negatable: true,
      hide: hide);
  parser.addOption(packagesOption,
      help: 'The path to the package resolution configuration file, which '
          'supplies a mapping of package names\nto paths. This option cannot be '
          'used with --package-root.',
      hide: ddc);
  parser.addOption(sdkSummaryPathOption,
      help: 'The path to the Dart SDK summary file.', hide: hide);
  parser.addFlag(enableInitializingFormalAccessFlag,
      help:
          'Enable support for allowing access to field formal parameters in a '
          'constructor\'s initializer list.',
      defaultsTo: false,
      negatable: false,
      hide: hide || ddc);
  parser.addFlag(enableSuperMixinFlag,
      help: 'Relax restrictions on mixins (DEP 34).',
      defaultsTo: false,
      negatable: false,
      hide: hide);
  if (!ddc) {
    parser.addFlag(lintsFlag,
        help: 'Show lint results.', defaultsTo: false, negatable: true);
  }
}

/**
 * Find arguments of the form -Dkey=value
 * or argument pairs of the form -Dkey value
 * and place those key/value pairs into [definedVariables].
 * Return a list of arguments with the key/value arguments removed.
 */
List<String> extractDefinedVariables(
    List<String> args, Map<String, String> definedVariables) {
  //TODO(danrubel) extracting defined variables is already handled by the
  // createContextBuilderOptions method.
  // Long term we should switch to using that instead.
  int count = args.length;
  List<String> remainingArgs = <String>[];
  for (int i = 0; i < count; i++) {
    String arg = args[i];
    if (arg == '--') {
      while (i < count) {
        remainingArgs.add(args[i++]);
      }
    } else if (arg.startsWith("-D")) {
      int end = arg.indexOf('=');
      if (end > 2) {
        definedVariables[arg.substring(2, end)] = arg.substring(end + 1);
      } else if (i + 1 < count) {
        definedVariables[arg.substring(2)] = args[++i];
      } else {
        remainingArgs.add(arg);
      }
    } else {
      remainingArgs.add(arg);
    }
  }
  return remainingArgs;
}

/**
 * Return a list of command-line arguments containing all of the given [args]
 * that are defined by the given [parser]. An argument is considered to be
 * defined by the parser if
 * - it starts with '--' and the rest of the argument (minus any value
 *   introduced by '=') is the name of a known option,
 * - it starts with '-' and the rest of the argument (minus any value
 *   introduced by '=') is the name of a known abbreviation, or
 * - it starts with something other than '--' or '-'.
 *
 * This function allows command-line tools to implement the
 * '--ignore-unrecognized-flags' option.
 */
List<String> filterUnknownArguments(List<String> args, ArgParser parser) {
  Set<String> knownOptions = new HashSet<String>();
  Set<String> knownAbbreviations = new HashSet<String>();
  parser.options.forEach((String name, Option option) {
    knownOptions.add(name);
    String abbreviation = option.abbr;
    if (abbreviation != null) {
      knownAbbreviations.add(abbreviation);
    }
  });
  String optionName(int prefixLength, String argument) {
    int equalsOffset = argument.lastIndexOf('=');
    if (equalsOffset < 0) {
      return argument.substring(prefixLength);
    }
    return argument.substring(prefixLength, equalsOffset);
  }

  List<String> filtered = <String>[];
  for (int i = 0; i < args.length; i++) {
    String argument = args[i];
    if (argument.startsWith('--') && argument.length > 2) {
      if (knownOptions.contains(optionName(2, argument))) {
        filtered.add(argument);
      }
    } else if (argument.startsWith('-') && argument.length > 1) {
      if (knownAbbreviations.contains(optionName(1, argument))) {
        filtered.add(argument);
      }
    } else {
      filtered.add(argument);
    }
  }
  return filtered;
}

/**
 * Use the given [parser] to parse the given command-line [args], and return the
 * result.
 */
ArgResults parse(
    ResourceProvider provider, ArgParser parser, List<String> args) {
  args = preprocessArgs(provider, args);
  if (args.contains('--$ignoreUnrecognizedFlagsFlag')) {
    args = filterUnknownArguments(args, parser);
  }
  return parser.parse(args);
}

/**
 * Preprocess the given list of command line [args].
 * If the final arg is `@file_path` (Bazel worker mode),
 * then read in all the lines of that file and add those as args.
 * Always returns a new modifiable list.
 */
List<String> preprocessArgs(ResourceProvider provider, List<String> args) {
  args = new List.from(args);
  if (args.isEmpty) {
    return args;
  }
  String lastArg = args.last;
  if (lastArg.startsWith('@')) {
    File argsFile = provider.getFile(lastArg.substring(1));
    try {
      args.removeLast();
      args.addAll(argsFile
          .readAsStringSync()
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .split('\n')
          .where((String line) => line.isNotEmpty));
    } on FileSystemException catch (e) {
      throw new Exception('Failed to read file specified by $lastArg : $e');
    }
  }
  return args;
}
