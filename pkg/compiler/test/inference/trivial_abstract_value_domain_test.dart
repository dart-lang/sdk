// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';

import '../helpers/args_helper.dart';
import '../helpers/memory_compiler.dart';

main(List<String> args) {
  ArgParser argParser = createArgParser();

  asyncTest(() async {
    ArgResults argResults = argParser.parse(args);
    Uri entryPoint = getEntryPoint(argResults) ??
        Uri.base.resolve('samples-dev/swarm/swarm.dart');
    Uri librariesSpecificationUri = getLibrariesSpec(argResults);
    Uri packageConfig = getPackages(argResults);
    List<String> options = getOptions(argResults);
    await runCompiler(
        entryPoint: entryPoint,
        packageConfig: packageConfig,
        librariesSpecificationUri: librariesSpecificationUri,
        options: [Flags.useTrivialAbstractValueDomain]..addAll(options));
  });
}
