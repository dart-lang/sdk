// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// @dart = 2.9

library fasta.test.weak_test;

import 'testing/suite.dart';

Future<FastaContext> createContext(
    Chain suite, Map<String, String> environment) {
  environment[ENABLE_FULL_COMPILE] = "";
  return FastaContext.create(suite, environment);
}

main(List<String> arguments) {
  internalMain(arguments: arguments);
}

internalMain(
        {List<String> arguments = const [], int shards = 1, int shard = 0}) =>
    runMe(arguments, createContext,
        configurationPath: "../../testing.json", shard: shard, shards: shards);
