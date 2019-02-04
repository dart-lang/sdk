// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.fast_legacy_test;

import 'dart:async' show Future;

import 'dart:io' show Platform;

import 'testing/suite.dart';

Future<FastaContext> createContext(
    Chain suite, Map<String, String> environment) {
  environment[ENABLE_FULL_COMPILE] = "";
  environment[LEGACY_MODE] = "";
  environment["skipVm"] = "true";
  return FastaContext.create(suite, environment);
}

main([List<String> arguments = const []]) => runMe(arguments, createContext,
    "../../testing.json", Platform.script.resolve("legacy_test.dart"));
