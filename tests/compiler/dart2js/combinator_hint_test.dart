// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the hint on empty combinators works as intended.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'memory_compiler.dart';

const SOURCE = const {
  'show_local.dart': """
import 'lib.dart' show Foo;
""",

  'hide_local.dart': """
import 'lib.dart' hide Foo;
""",

  'show_package.dart': """
import 'package:pkg/pkg.dart' show Foo;
""",

  'hide_package.dart': """
import 'package:pkg/pkg.dart' hide Foo;
""",

  'lib.dart': '',

  'pkg/pkg/pkg.dart': '',
};

Future test(Uri entryPoint,
            {bool showPackageWarnings: false,
             bool suppressHints: false,
             int hints: 0}) async {
  print('==================================================================');
  print('test: $entryPoint showPackageWarnings=$showPackageWarnings '
        'suppressHints=$suppressHints');
  var options = [Flags.analyzeOnly, Flags.analyzeAll];
  if (showPackageWarnings) {
    options.add(Flags.showPackageWarnings);
  }
  if (suppressHints) {
    options.add(Flags.suppressHints);
  }
  var collector = new DiagnosticCollector();
  await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: SOURCE,
      options: options,
      packageRoot: Uri.parse('memory:pkg/'),
      diagnosticHandler: collector);
  Expect.equals(0, collector.errors.length,
                'Unexpected errors: ${collector.errors}');
  Expect.equals(0, collector.warnings.length,
                'Unexpected warnings: ${collector.warnings}');
  Expect.equals(hints, collector.hints.length,
                'Unexpected hints: ${collector.hints}');
  Expect.equals(0, collector.infos.length,
                'Unexpected infos: ${collector.infos}');
  print('==================================================================');
}

Future testUri(Uri entrypoint, {bool suppressed: false}) async {
  await test(
      entrypoint,
      showPackageWarnings: true,
      suppressHints: false,
      hints: 1);
  await test(
      entrypoint,
      showPackageWarnings: false,
      suppressHints: false,
      hints: suppressed ? 0 : 1);
  await test(
      entrypoint,
      showPackageWarnings: true,
      suppressHints: true,
      hints: 0);
  await test(
      entrypoint,
      showPackageWarnings: false,
      suppressHints: true,
      hints: 0);
}

void main() {
  asyncTest(() async {
    await testUri(Uri.parse('memory:show_local.dart'));
    await testUri(Uri.parse('memory:hide_local.dart'));
    await testUri(Uri.parse('memory:show_package.dart'));
    await testUri(Uri.parse('memory:hide_package.dart'), suppressed: true);
  });
}

