// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.dart_vm_suite;

import 'testing.dart';

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return new VmContext();
}

class VmContext extends ChainContext {
  final List<Step> steps = const <Step>[const DartVmStep()];
}

class DartVmStep extends Step<TestDescription, int, VmContext> {
  const DartVmStep();

  String get name => "Dart VM";

  Future<Result<int>> run(TestDescription input, VmContext context) async {
    StdioProcess process = await StdioProcess.run("dart", [input.file.path]);
    return process.toResult();
  }
}

main(List<String> arguments) => runMe(arguments, createContext);
