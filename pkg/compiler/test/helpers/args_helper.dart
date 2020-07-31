// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:_fe_analyzer_shared/src/util/filenames.dart';
import 'package:args/args.dart';
import 'package:compiler/src/commandline_options.dart';

/// Creates an [ArgParser] that supports various dart2js command-line options.
ArgParser createArgParser() {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag('fast-startup', defaultsTo: false);
  argParser.addFlag('omit-implicit-checks', defaultsTo: false);
  argParser.addFlag('minify', abbr: 'm', defaultsTo: false);
  argParser.addFlag('trust-primitives', defaultsTo: false);
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  argParser.addOption('libraries-spec');
  argParser.addOption('packages');
  return argParser;
}

/// Retrieves the entry point [Uri] from [argResults].
Uri getEntryPoint(ArgResults argResults) {
  Uri entryPoint;
  if (argResults.rest.isNotEmpty) {
    if (argResults.rest.length > 1) {
      throw new ArgumentError(
          'Extra arguments: ${argResults.rest.skip(1).join(" ")}');
    }
    entryPoint = Uri.base.resolve(nativeToUriPath(argResults.rest.single));
  }
  return entryPoint;
}

/// Retrieves the library root [Uri] from [argResults].
Uri getLibrariesSpec(ArgResults argResults) {
  if (!argResults.wasParsed('libraries-spec')) return null;
  return Uri.base.resolve(nativeToUriPath(argResults['libraries-spec']));
}

/// Retrieves the packages config [Uri] from [argResults].
Uri getPackages(ArgResults argResults) {
  Uri packageConfig;
  if (argResults.wasParsed('packages')) {
    packageConfig = Uri.base.resolve(nativeToUriPath(argResults['packages']));
  }
  return packageConfig;
}

/// Retrieves the options from [argResults].
List<String> getOptions(ArgResults argResults) {
  List<String> options = <String>[];
  if (argResults['fast-startup']) {
    options.add(Flags.fastStartup);
  }
  if (argResults['omit-implicit-checks']) {
    options.add(Flags.omitImplicitChecks);
  }
  if (argResults['minify']) {
    options.add(Flags.minify);
  }
  if (argResults['trust-primitives']) {
    options.add(Flags.trustPrimitives);
  }
  if (argResults['verbose']) {
    options.add(Flags.verbose);
  }
  return options;
}
