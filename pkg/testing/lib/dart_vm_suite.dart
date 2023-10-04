// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library testing.dart_vm_suite;

import 'testing.dart';

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return VmContext();
}

class VmContext extends ChainContext {
  @override
  final List<Step> steps = const <Step>[DartVmStep()];
}

class DartVmStep extends Step<FileBasedTestDescription, int, VmContext> {
  const DartVmStep();

  @override
  String get name => "Dart VM";

  @override
  Future<Result<int>> run(
      FileBasedTestDescription input, VmContext context) async {
    StdioProcess process = await StdioProcess.run("dart", [input.file.path]);
    return process.toResult();
  }
}

main(List<String> arguments) => runMe(arguments, createContext);
