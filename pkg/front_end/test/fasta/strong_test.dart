// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.strong_test;

import 'dart:async' show Future;

import 'testing/suite.dart';

Future<FastaContext> createContext(
    Chain suite, Map<String, String> environment) {
  environment[ENABLE_FULL_COMPILE] = "";
  return FastaContext.create(suite, environment);
}

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, "../../testing.json");
