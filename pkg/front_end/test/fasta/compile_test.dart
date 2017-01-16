// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.compile_test;

import 'dart:async' show
    Future;

import 'package:fasta/testing/suite.dart';

Future<FeContext> createContext(
    Chain suite, Map<String, String> environment) {
  environment[ENABLE_FULL_COMPILE] = "";
  environment[AST_KIND_INDEX] = "${AstKind.Kernel.index}";
  return TestContext.create(suite, environment, FeContext.create);
}

main(List<String> arguments) => runMe(arguments, createContext);
