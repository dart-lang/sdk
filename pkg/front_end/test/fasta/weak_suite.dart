// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.weak_test;

import 'testing/suite.dart';

Future<FastaContext> createContext(
    Chain suite, Map<String, String> environment) {
  environment[ENABLE_FULL_COMPILE] = "";
  environment["weak"] = "true";
  return FastaContext.create(suite, environment);
}

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../../testing.json");
