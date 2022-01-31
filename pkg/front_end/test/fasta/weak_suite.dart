// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.weak_test;

import 'testing/suite.dart';

Future<FastaContext> createContext(
    Chain suite, Map<String, String> environment) {
  environment[COMPILATION_MODE] = CompileMode.full.name;
  return FastaContext.create(suite, environment);
}

void main(List<String> arguments) {
  internalMain(arguments: arguments);
}

void internalMain(
        {List<String> arguments = const [], int shards = 1, int shard = 0}) =>
    runMe(arguments, createContext,
        configurationPath: "../../testing.json", shard: shard, shards: shards);
