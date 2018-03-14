// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';

import "../memory_compiler.dart";

runTest(String source, String categories, int expectedErrors) async {
  var collector = new DiagnosticCollector();
  await runCompiler(
      memorySourceFiles: {"main.dart": source},
      options: ["--categories=$categories", Flags.useOldFrontend],
      diagnosticHandler: collector);
  Expect.equals(expectedErrors, collector.errors.length);
  Expect.equals(0, collector.warnings.length);
}

void main() {
  asyncTest(() async {
    await runTest("import 'dart:async'; main() {}", "Client", 0);
    await runTest("import 'dart:async'; main() {}", "Server", 0);
    await runTest("import 'dart:html'; main() {}", "Client", 0);
    await runTest("import 'dart:html'; main() {}", "Server", 1);
    // Importing dart:io is temporarily allowed as a stopgap measure for the
    // lack of config specific imports. Once that is added, this will be
    // disallowed again.
    await runTest("import 'dart:io'; main() {}", "Client", 0);
    await runTest("import 'dart:io'; main() {}", "Server", 0);
  });
}
