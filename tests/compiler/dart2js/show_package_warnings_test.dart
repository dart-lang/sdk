// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the '--show-package-warnings' option works as intended.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'memory_compiler.dart';

/// Error code that creates 1 warning, 1 hint, and 1 info.
const ERROR_CODE = """
m(Object o) {
  if (o is String) {
    o = o.length;
  }
}""";

const SOURCE = const {
  'main.dart': """
import 'package:pkg_error1/pkg_error1.dart';
import 'package:pkg_error2/pkg_error2.dart';
import 'package:pkg_noerror/pkg_noerror.dart';
import 'error.dart';
""",

  'error.dart': ERROR_CODE,

  'pkg/pkg_error1/pkg_error1.dart': """
import 'package:pkg_error2/pkg_error2.dart';
import 'package:pkg_noerror/pkg_noerror.dart';
$ERROR_CODE""",

  'pkg/pkg_error2/pkg_error2.dart': """
import 'package:pkg_error1/pkg_error1.dart';
import 'package:pkg_noerror/pkg_noerror.dart';
$ERROR_CODE""",

  'pkg/pkg_noerror/pkg_noerror.dart': """
import 'package:pkg_error1/pkg_error1.dart';
import 'package:pkg_error2/pkg_error2.dart';
"""};

Future test(Uri entryPoint,
            {bool showPackageWarnings: false,
             int warnings: 0,
             int hints: 0,
             int infos: 0}) async {
  var options = [Flags.analyzeOnly, Flags.analyzeAll];
  if (showPackageWarnings) {
    options.add(Flags.showPackageWarnings);
  }
  var collector = new DiagnosticCollector();
  await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: SOURCE,
      options: options,
      packageRoot: Uri.parse('memory:pkg/'),
      diagnosticHandler: collector);
  print('==================================================================');
  print('test: $entryPoint showPackageWarnings=$showPackageWarnings');
  Expect.equals(0, collector.errors.length,
                'Unexpected errors: ${collector.errors}');
  Expect.equals(warnings, collector.warnings.length,
                'Unexpected warnings: ${collector.warnings}');
  checkUriSchemes(collector.warnings);
  Expect.equals(hints, collector.hints.length,
                'Unexpected hints: ${collector.hints}');
  checkUriSchemes(collector.hints);
  Expect.equals(infos, collector.infos.length,
                'Unexpected infos: ${collector.infos}');
  checkUriSchemes(collector.infos);
  print('==================================================================');
}

void checkUriSchemes(Iterable<DiagnosticMessage> messages) {
  for (DiagnosticMessage message in messages) {
    if (message.uri != null) {
      Expect.notEquals('package', message.uri.scheme,
          "Unexpected package uri `${message.uri}` in message: $message");
    }
  }
}

void main() {
  asyncTest(() async {
    await test(
        Uri.parse('memory:main.dart'),
        showPackageWarnings: true,
        // From error.dart, package:pkg_error1 and package:pkg_error2:
        warnings: 3, hints: 3, infos: 3);
    await test(
        Uri.parse('memory:main.dart'),
        showPackageWarnings: false,
        // From error.dart only:
        warnings: 1, hints: 1 + 2 /* from summary */, infos: 1);
    await test(
        Uri.parse('package:pkg_error1/pkg_error1.dart'),
        showPackageWarnings: true,
        // From package:pkg_error1 and package:pkg_error2:
        warnings: 2, hints: 2, infos: 2);
    await test(
        Uri.parse('package:pkg_error1/pkg_error1.dart'),
        showPackageWarnings: false,
        // From package:pkg_error1/pkg_error1.dart only:
        warnings: 1, hints: 1 + 1 /* from summary */, infos: 1);
    await test(
        Uri.parse('package:pkg_noerror/pkg_noerror.dart'),
        showPackageWarnings: true,
        // From package:pkg_error1 and package:pkg_error2:
        warnings: 2, hints: 2, infos: 2);
    await test(
        Uri.parse('package:pkg_noerror/pkg_noerror.dart'),
        showPackageWarnings: false,
        hints: 2 /* from summary */);
  });
}

