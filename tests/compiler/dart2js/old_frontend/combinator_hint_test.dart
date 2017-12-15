// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the hint on empty combinators works as intended.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import '../memory_compiler.dart';

const SOURCE = const {
  'show_local.dart': """
import 'lib.dart' show Foo;

main() {}
""",
  'hide_local.dart': """
import 'lib.dart' hide Foo;

main() {}
""",
  'show_package.dart': """
import 'package:pkg/pkg.dart' show Foo;

main() {}
""",
  'hide_package.dart': """
import 'package:pkg/pkg.dart' hide Foo;

main() {}
""",
  'lib.dart': '',
  'pkg/pkg/pkg.dart': '',
};

Future<Compiler> test(Uri entryPoint,
    {bool showPackageWarnings: false,
    bool suppressHints: false,
    int hints: 0,
    Compiler cachedCompiler}) async {
  print('==================================================================');
  print('test: $entryPoint showPackageWarnings=$showPackageWarnings '
      'suppressHints=$suppressHints');
  var options = [Flags.analyzeOnly];
  if (showPackageWarnings) {
    options.add(Flags.showPackageWarnings);
  }
  if (suppressHints) {
    options.add(Flags.suppressHints);
  }
  var collector = new DiagnosticCollector();
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: SOURCE,
      options: options,
      packageRoot: Uri.parse('memory:pkg/'),
      diagnosticHandler: collector,
      cachedCompiler: cachedCompiler);
  Expect.equals(
      0, collector.errors.length, 'Unexpected errors: ${collector.errors}');
  Expect.equals(0, collector.warnings.length,
      'Unexpected warnings: ${collector.warnings}');
  Expect.equals(
      hints, collector.hints.length, 'Unexpected hints: ${collector.hints}');
  Expect.equals(
      0, collector.infos.length, 'Unexpected infos: ${collector.infos}');
  print('==================================================================');
  return result.compiler;
}

Future<Compiler> testUri(Uri entrypoint,
    {bool suppressed: false, Compiler cachedCompiler}) async {
  cachedCompiler = await test(entrypoint,
      showPackageWarnings: true,
      suppressHints: false,
      hints: 1,
      cachedCompiler: cachedCompiler);
  cachedCompiler = await test(entrypoint,
      showPackageWarnings: false,
      suppressHints: false,
      hints: suppressed ? 0 : 1,
      cachedCompiler: cachedCompiler);
  cachedCompiler = await test(entrypoint,
      showPackageWarnings: true,
      suppressHints: true,
      hints: 0,
      cachedCompiler: cachedCompiler);
  cachedCompiler = await test(entrypoint,
      showPackageWarnings: false,
      suppressHints: true,
      hints: 0,
      cachedCompiler: cachedCompiler);
  return cachedCompiler;
}

void main() {
  asyncTest(() async {
    Compiler cachedCompiler =
        await testUri(Uri.parse('memory:show_local.dart'));
    cachedCompiler = await testUri(Uri.parse('memory:hide_local.dart'),
        cachedCompiler: cachedCompiler);
    cachedCompiler = await testUri(Uri.parse('memory:show_package.dart'),
        cachedCompiler: cachedCompiler);
    cachedCompiler = await testUri(Uri.parse('memory:hide_package.dart'),
        suppressed: true, cachedCompiler: cachedCompiler);
  });
}
