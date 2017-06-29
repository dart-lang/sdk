// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.outline_test;

import 'dart:async' show Future;

import 'testing/suite.dart';

Future<FastaContext> createContext(
    Chain suite, Map<String, String> environment) {
  return FastaContext.create(suite, environment);
}

main(List<String> arguments) =>
    runMe(arguments, createContext, "../../testing.json");
