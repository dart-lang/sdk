// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.strong_test;

import 'dart:io' show Platform;

import 'testing/suite.dart';

const int shardCount = 4;

Future<FastaContext> createContext(
    Chain suite, Map<String, String> environment) {
  environment[ENABLE_FULL_COMPILE] = "";
  return FastaContext.create(suite, environment);
}

main(List<String> arguments) {
  internalMain(arguments: arguments);
}

internalMain(
    {List<String> arguments = const [], int shards = 1, int shard = 0}) {
  runMe(arguments, createContext,
      configurationPath: "../../testing.json",
      me: Platform.script.resolve('strong_tester.dart'),
      shards: shards,
      shard: shard);
}
