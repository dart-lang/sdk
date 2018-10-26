// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/filenames.dart';
import 'serialization_test_helper.dart';

main(List<String> args) {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag('debug', abbr: 'd', defaultsTo: false);
  argParser.addFlag('object', abbr: 'o', defaultsTo: false);
  argParser.addFlag('kinds', abbr: 'k', defaultsTo: false);
  argParser.addFlag('fast-startup', defaultsTo: false);
  argParser.addFlag('omit-implicit-checks', defaultsTo: false);
  argParser.addFlag('minify', defaultsTo: false);
  argParser.addFlag('trust-primitives', defaultsTo: false);
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  argParser.addOption('library-root');
  argParser.addOption('packages');

  asyncTest(() async {
    ArgResults argResults = argParser.parse(args);
    SerializationStrategy strategy = SerializationStrategy.bytesInMemory;
    if (argResults['object'] || argResults['debug']) {
      strategy = SerializationStrategy.objectsInMemory;
    }
    bool useDataKinds = argResults['kinds'] || argResults['debug'];

    Uri entryPoint;
    if (argResults.rest.isEmpty) {
      entryPoint = Uri.base.resolve('samples-dev/swarm/swarm.dart');
    } else {
      entryPoint = Uri.base.resolve(nativeToUriPath(argResults.rest.last));
    }
    Uri libraryRoot;
    if (argResults.wasParsed('library-root')) {
      libraryRoot =
          Uri.base.resolve(nativeToUriPath(argResults['library-root']));
    }
    Uri packageConfig;
    if (argResults.wasParsed('packages')) {
      packageConfig = Uri.base.resolve(nativeToUriPath(argResults['packages']));
    }
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
    await runTest(
        entryPoint: entryPoint,
        packageConfig: packageConfig,
        libraryRoot: libraryRoot,
        options: options,
        strategy: strategy,
        useDataKinds: useDataKinds);
  });
}
