// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.compile_test;

import 'dart:async' show Future;

import 'testing/suite.dart';

import 'package:front_end/src/fasta/testing/kernel_chain.dart'
    show MatchExpectation;

Future<FastaContext> createContext(
    Chain suite, Map<String, String> environment) async {
  environment[ENABLE_FULL_COMPILE] = "";
  environment[AST_KIND_INDEX] = "${AstKind.Kernel.index}";
  FastaContext context = await FastaContext.create(suite, environment);
  int index;
  for (int i = 0; i < context.steps.length; i++) {
    if (context.steps[i] is MatchExpectation) {
      index = i;
      break;
    }
  }
  context.steps.removeAt(index);
  return context;
}

main(List<String> arguments) => runMe(arguments, createContext);
