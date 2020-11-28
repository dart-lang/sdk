// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:args/args.dart';

const String analysisOptionsFileOption = 'options';
const String defineVariableOption = 'D';
const String enableInitializingFormalAccessFlag = 'initializing-formal-access';
@deprecated
const String enableSuperMixinFlag = 'supermixin';
const String flutterAnalysisOptionsPath =
    'package:flutter/analysis_options_user.yaml';
const String ignoreUnrecognizedFlagsFlag = 'ignore-unrecognized-flags';
const String implicitCastsFlag = 'implicit-casts';
const String lintsFlag = 'lints';
const String noImplicitDynamicFlag = 'no-implicit-dynamic';
const String packagesOption = 'packages';
const String sdkPathOption = 'dart-sdk';

const String sdkSummaryPathOption = 'dart-sdk-summary';

/// Update [options] with the value of each analysis option command line flag.
void applyAnalysisOptionFlags(AnalysisOptionsImpl options, ArgResults args,
    {void Function(String text) verbosePrint}) {
  void verbose(String text) {
    if (verbosePrint != null) {
      verbosePrint('Analysis options: $text');
    }
  }

  if (args.wasParsed(implicitCastsFlag)) {
    options.implicitCasts = args[implicitCastsFlag];
    verbose('$implicitCastsFlag = ${options.implicitCasts}');
  }
  if (args.wasParsed(noImplicitDynamicFlag)) {
    options.implicitDynamic = !args[noImplicitDynamicFlag];
    verbose('$noImplicitDynamicFlag = ${options.implicitDynamic}');
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

/// Use the command-line [args] to create a context builder options.
ContextBuilderOptions createContextBuilderOptions(
  ResourceProvider resourceProvider,
  ArgResults args,
) {
  String absoluteNormalizedPath(String path) {
    if (path == null) {
      return null;
    }
    var pathContext = resourceProvider.pathContext;
    return pathContext.normalize(
      pathContext.absolute(path),
    );
  }

  ContextBuilderOptions builderOptions = ContextBuilderOptions();
  builderOptions.argResults = args;
  //
  // File locations.
  //
  builderOptions.dartSdkSummaryPath = absoluteNormalizedPath(
    args[sdkSummaryPathOption],
  );
  builderOptions.defaultAnalysisOptionsFilePath = absoluteNormalizedPath(
    args[analysisOptionsFileOption],
  );
  builderOptions.defaultPackageFilePath = absoluteNormalizedPath(
    args[packagesOption],
  );
  //
  // Analysis options.
  //
  AnalysisOptionsImpl defaultOptions = AnalysisOptionsImpl();
  applyAnalysisOptionFlags(defaultOptions, args);
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

/// Add the standard flags and options to the given [parser]. The standard flags
/// are those that are typically used to control the way in which the code is
/// analyzed.
///
/// TODO(danrubel) Update DDC to support all the options defined in this method
/// then remove the [ddc] named argument from this method.
void defineAnalysisArguments(ArgParser parser,
    {bool hide = true, bool ddc = false}) {
  parser.addOption(sdkPathOption,
      help: 'The path to the Dart SDK.', hide: ddc && hide);
  parser.addOption(analysisOptionsFileOption,
      help: 'Path to an analysis options file.', hide: ddc && hide);
  parser.addFlag('strong',
      help: 'Enable strong mode (deprecated); this option is now ignored.',
      defaultsTo: true,
      hide: true,
      negatable: true);
  parser.addFlag('declaration-casts',
      negatable: true,
      help: 'Disable declaration casts in strong mode (https://goo.gl/cTLz40)\n'
          'This option is now ignored and will be removed in a future release.',
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
      help:
          'Define an environment declaration. For example, "-Dfoo=bar" defines '
          'an environment declaration named "foo" whose value is "bar".',
      hide: hide);
  parser.addOption(packagesOption,
      help: 'The path to the package resolution configuration file, which '
          'supplies a mapping of package names\nto paths.',
      hide: ddc);
  parser.addOption(sdkSummaryPathOption,
      help: 'The path to the Dart SDK summary file.', hide: hide);
  parser.addFlag(enableInitializingFormalAccessFlag,
      help:
          'Enable support for allowing access to field formal parameters in a '
          'constructor\'s initializer list (deprecated).',
      defaultsTo: false,
      negatable: false,
      hide: hide || ddc);
  if (!ddc) {
    parser.addFlag(lintsFlag,
        help: 'Show lint results.', defaultsTo: false, negatable: true);
  }
}

/// Find arguments of the form -Dkey=value
/// or argument pairs of the form -Dkey value
/// and place those key/value pairs into [definedVariables].
/// Return a list of arguments with the key/value arguments removed.
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

/// Return a list of command-line arguments containing all of the given [args]
/// that are defined by the given [parser]. An argument is considered to be
/// defined by the parser if
/// - it starts with '--' and the rest of the argument (minus any value
///   introduced by '=') is the name of a known option,
/// - it starts with '-' and the rest of the argument (minus any value
///   introduced by '=') is the name of a known abbreviation, or
/// - it starts with something other than '--' or '-'.
///
/// This function allows command-line tools to implement the
/// '--ignore-unrecognized-flags' option.
List<String> filterUnknownArguments(List<String> args, ArgParser parser) {
  Set<String> knownOptions = HashSet<String>();
  Set<String> knownAbbreviations = HashSet<String>();
  parser.options.forEach((String name, Option option) {
    knownOptions.add(name);
    String abbreviation = option.abbr;
    if (abbreviation != null) {
      knownAbbreviations.add(abbreviation);
    }
    if (option.negatable) {
      knownOptions.add('no-$name');
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

/// Use the given [parser] to parse the given command-line [args], and return
/// the result.
ArgResults parse(
    ResourceProvider provider, ArgParser parser, List<String> args) {
  args = preprocessArgs(provider, args);
  if (args.contains('--$ignoreUnrecognizedFlagsFlag')) {
    args = filterUnknownArguments(args, parser);
  }
  return parser.parse(args);
}

/// Preprocess the given list of command line [args].
/// If the final arg is `@file_path` (Bazel worker mode),
/// then read in all the lines of that file and add those as args.
/// Always returns a new modifiable list.
List<String> preprocessArgs(ResourceProvider provider, List<String> args) {
  args = List.from(args);
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
      throw Exception('Failed to read file specified by $lastArg : $e');
    }
  }
  return args;
}
