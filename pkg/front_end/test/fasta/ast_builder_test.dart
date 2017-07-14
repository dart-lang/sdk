// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:async' show Future;

import 'testing/suite.dart';

Future<FastaContext> createContext(
    Chain suite, Map<String, String> environment) {
  environment[ENABLE_FULL_COMPILE] = "";
  environment[AST_KIND_INDEX] = "${AstKind.Analyzer.index}";
  environment[STRONG_MODE] = "";
  return FastaContext.create(suite, environment);
}

main(List<String> arguments) =>
    runMe(arguments, createContext, "../../testing.json");
