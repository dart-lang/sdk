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
const String defineVariableOption = 'D';
const String enableInitializingFormalAccessFlag = 'initializing-formal-access';
const String enableStrictCallChecksFlag = 'enable-strict-call-checks';
const String enableSuperInMixinFlag = 'supermixin';
const String ignoreUnrecognizedFlagsFlag = 'ignore_unrecognized_flags';
const String noImplicitCastsFlag = 'no-implicit-casts';
const String noImplicitDynamicFlag = 'no-implicit-dynamic';
const String packageRootOption = 'package-root';
const String packagesOption = 'packages';
const String sdkPathOption = 'dart-sdk';
const String sdkSummaryPathOption = 'dart-sdk-summary';
const String strongModeFlag = 'strong';

/**
 * Use the given [resourceProvider], [contentCache] and command-line [args] to
 * create a context builder.
 */
ContextBuilderOptions createContextBuilderOptions(ArgResults args) {
  ContextBuilderOptions builderOptions = new ContextBuilderOptions();
  //
  // File locations.
  //
  builderOptions.dartSdkSummaryPath = args[sdkSummaryPathOption];
  builderOptions.defaultAnalysisOptionsFilePath =
      args[analysisOptionsFileOption];
  builderOptions.defaultPackageFilePath = args[packagesOption];
  builderOptions.defaultPackagesDirectoryPath = args[packageRootOption];
  //
  // Analysis options.
  //
  AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
  defaultOptions.enableInitializingFormalAccess =
      args[enableInitializingFormalAccessFlag];
  defaultOptions.enableStrictCallChecks = args[enableStrictCallChecksFlag];
  defaultOptions.enableSuperMixins = args[enableSuperInMixinFlag];
  defaultOptions.implicitCasts = !args[noImplicitCastsFlag];
  defaultOptions.implicitDynamic = !args[noImplicitDynamicFlag];
  defaultOptions.strongMode = args[strongModeFlag];
  builderOptions.defaultOptions = defaultOptions;
  //
  // Declared variables.
  //
  Map<String, String> declaredVariables = <String, String>{};
  List<String> variables = args[defineVariableOption] as List<String>;
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
 */
void defineAnalysisArguments(ArgParser parser) {
  parser.addOption(defineVariableOption,
      abbr: 'D',
      allowMultiple: true,
      help: 'Define environment variables. For example, "-Dfoo=bar" defines an '
          'environment variable named "foo" whose value is "bar".');
  parser.addOption(sdkPathOption, help: 'The path to the Dart SDK.');
  parser.addOption(sdkSummaryPathOption,
      help: 'The path to the Dart SDK summary file.', hide: true);
  parser.addOption(analysisOptionsFileOption,
      help: 'Path to an analysis options file.');
  parser.addOption(packagesOption,
      help: 'The path to the package resolution configuration file, which '
          'supplies a mapping of package names to paths. This option cannot be '
          'used with --package-root.');
  parser.addOption(packageRootOption,
      abbr: 'p',
      help: 'The path to a package root directory (deprecated). This option '
          'cannot be used with --packages.');

  parser.addFlag(strongModeFlag,
      help: 'Enable strong static checks (https://goo.gl/DqcBsw)');
  parser.addFlag(noImplicitCastsFlag,
      negatable: false,
      help: 'Disable implicit casts in strong mode (https://goo.gl/cTLz40)');
  parser.addFlag(noImplicitDynamicFlag,
      negatable: false,
      help: 'Disable implicit dynamic (https://goo.gl/m0UgXD)');
  //
  // Hidden flags and options.
  //
//  parser.addFlag(enableNullAwareOperatorsFlag, // 'enable-null-aware-operators'
//      help: 'Enable support for null-aware operators (DEP 9).',
//      defaultsTo: false,
//      negatable: false,
//      hide: true);
  parser.addFlag(enableStrictCallChecksFlag,
      help: 'Fix issue 21938.',
      defaultsTo: false,
      negatable: false,
      hide: true);
  parser.addFlag(enableInitializingFormalAccessFlag,
      help:
          'Enable support for allowing access to field formal parameters in a '
          'constructor\'s initializer list',
      defaultsTo: false,
      negatable: false,
      hide: true);
  parser.addFlag(enableSuperInMixinFlag,
      help: 'Relax restrictions on mixins (DEP 34).',
      defaultsTo: false,
      negatable: false,
      hide: true);
//  parser.addFlag('enable_type_checks',
//      help: 'Check types in constant evaluation.',
//      defaultsTo: false,
//      negatable: false,
//      hide: true);
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
 * '--ignore_unrecognized_flags' option.
 */
List<String> filterUnknownArguments(List<String> args, ArgParser parser) {
  Set<String> knownOptions = new HashSet<String>();
  Set<String> knownAbbreviations = new HashSet<String>();
  parser.options.forEach((String name, Option option) {
    knownOptions.add(name);
    String abbreviation = option.abbreviation;
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
 * Preprocess the given list of command line [args] by checking whether the real
 * arguments are in a file (Bazel worker mode).
 */
List<String> preprocessArgs(ResourceProvider provider, List<String> args) {
  if (args.isEmpty) {
    return args;
  }
  String lastArg = args.last;
  if (lastArg.startsWith('@')) {
    File argsFile = provider.getFile(lastArg.substring(1));
    try {
      List<String> newArgs = args.sublist(0, args.length - 1).toList();
      newArgs.addAll(argsFile
          .readAsStringSync()
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .split('\n')
          .where((String line) => line.isNotEmpty));
      return newArgs;
    } on FileSystemException {
      // Don't modify args if the file does not exist or cannot be read.
    }
  }
  return args;
}
