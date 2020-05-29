// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/serialization/strategies.dart';
import 'serialization_test_helper.dart';
import '../helpers/args_helper.dart';

main(List<String> args) {
  ArgParser argParser = createArgParser();
  argParser.addFlag('debug', abbr: 'd', defaultsTo: false);
  argParser.addFlag('object', abbr: 'o', defaultsTo: false);
  argParser.addFlag('kinds', abbr: 'k', defaultsTo: false);

  asyncTest(() async {
    ArgResults argResults = argParser.parse(args);
    bool useDataKinds = argResults['kinds'] || argResults['debug'];
    SerializationStrategy strategy =
        new BytesInMemorySerializationStrategy(useDataKinds: useDataKinds);
    if (argResults['object'] || argResults['debug']) {
      strategy =
          new ObjectsInMemorySerializationStrategy(useDataKinds: useDataKinds);
    }

    Uri entryPoint = getEntryPoint(argResults) ??
        Uri.base.resolve('samples-dev/swarm/swarm.dart');
    Uri librariesSpecificationUri = getLibrariesSpec(argResults);
    Uri packageConfig = getPackages(argResults);
    List<String> options = getOptions(argResults);
    await runTest(
        entryPoint: entryPoint,
        packageConfig: packageConfig,
        librariesSpecificationUri: librariesSpecificationUri,
        options: options,
        strategy: strategy,
        useDataKinds: useDataKinds);
  });
}
