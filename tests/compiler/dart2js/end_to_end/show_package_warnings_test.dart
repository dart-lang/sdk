// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that the '--show-package-warnings' option works as intended.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import '../helpers/memory_compiler.dart';

/// Error code that creates 1 warning, 1 hint, and 1 info.
const ERROR_CODE = """
m(Object o) {
  if (o is String) {
    o = o.length;
  }
}""";

const SOURCE = const {
  'main.dart': """
import 'package:pkg_error1/pkg_error1.dart' as pkg1;
import 'package:pkg_error2/pkg_error2.dart' as pkg2;
import 'package:pkg_noerror/pkg_noerror.dart' as pkg3;
import 'error.dart' as error;

main() {
  pkg1.m(null);
  pkg2.m(null);
  pkg3.m(null);
  error.m(null);
}
""",
  'error.dart': ERROR_CODE,
  'pkg/pkg_error1/pkg_error1.dart': """
import 'package:pkg_error2/pkg_error2.dart' as pkg2;
import 'package:pkg_noerror/pkg_noerror.dart' as pkg3;
$ERROR_CODE

main() {
  m(null);
  pkg2.m(null);
  pkg3.m(null);
}
""",
  'pkg/pkg_error2/pkg_error2.dart': """
import 'package:pkg_error1/pkg_error1.dart' as pkg1;
import 'package:pkg_noerror/pkg_noerror.dart' as pkg3;
$ERROR_CODE

main() {
  pkg1.m(null);
  m(null);
  pkg3.m(null);
}
""",
  'pkg/pkg_noerror/pkg_noerror.dart': """
import 'package:pkg_error1/pkg_error1.dart' as pkg1;
import 'package:pkg_error2/pkg_error2.dart' as pkg2;
m(o) {}

main() {
  pkg1.m(null);
  m(null);
  pkg2.m(null);
}
""",
  '.packages': """
pkg_error1:pkg/pkg_error1/
pkg_error2:pkg/pkg_error2/
pkg_noerror:pkg/pkg_noerror/
"""
};

Future test(Uri entryPoint,
    {List<String> showPackageWarnings: null,
    int warnings: 0,
    int hints: 0,
    int infos: 0}) async {
  List<String> options = <String>[];
  if (showPackageWarnings != null) {
    if (showPackageWarnings.isEmpty) {
      options.add(Flags.showPackageWarnings);
    } else {
      options
          .add('${Flags.showPackageWarnings}=${showPackageWarnings.join(',')}');
    }
  }
  var collector = new DiagnosticCollector();
  print('==================================================================');
  print('test: $entryPoint showPackageWarnings=$showPackageWarnings');
  print('------------------------------------------------------------------');
  await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: SOURCE,
      options: options,
      packageConfig: Uri.parse('memory:.packages'),
      diagnosticHandler: collector);
  Expect.equals(
      0, collector.errors.length, 'Unexpected errors: ${collector.errors}');
  Expect.equals(warnings, collector.warnings.length,
      'Unexpected warnings: ${collector.warnings}');
  checkUriSchemes(collector.warnings);
  Expect.equals(
      hints, collector.hints.length, 'Unexpected hints: ${collector.hints}');
  checkUriSchemes(collector.hints);
  Expect.equals(
      infos, collector.infos.length, 'Unexpected infos: ${collector.infos}');
  checkUriSchemes(collector.infos);
}

void checkUriSchemes(Iterable<CollectedMessage> messages) {
  for (CollectedMessage message in messages) {
    if (message.uri != null) {
      Expect.notEquals('package', message.uri.scheme,
          "Unexpected package uri `${message.uri}` in message: $message");
    }
  }
}

void main() {
  asyncTest(() async {
    await test(Uri.parse('memory:main.dart'),
        showPackageWarnings: [],
        // From error.dart, package:pkg_error1 and package:pkg_error2:
        warnings: 3,
        hints: 3,
        infos: 3);
    await test(Uri.parse('memory:main.dart'),
        showPackageWarnings: ['pkg_error1'],
        // From error.dart and package:pkg_error1:
        warnings: 2,
        hints: 2 + 1 /* from summary */,
        infos: 2);
    await test(Uri.parse('memory:main.dart'),
        showPackageWarnings: ['pkg_error1', 'pkg_error2'],
        // From error.dart, package:pkg_error1 and package:pkg_error2:
        warnings: 3,
        hints: 3,
        infos: 3);
    await test(Uri.parse('memory:main.dart'),
        showPackageWarnings: [],
        // From error.dart, package:pkg_error1 and package:pkg_error2:
        warnings: 3,
        hints: 3,
        infos: 3);
    await test(Uri.parse('memory:main.dart'),
        showPackageWarnings: null,
        // From error.dart only:
        warnings: 1,
        hints: 1 + 2 /* from summary */,
        infos: 1);
    await test(Uri.parse('package:pkg_error1/pkg_error1.dart'),
        showPackageWarnings: [],
        // From package:pkg_error1 and package:pkg_error2:
        warnings: 2,
        hints: 2,
        infos: 2);
    await test(Uri.parse('package:pkg_error1/pkg_error1.dart'),
        showPackageWarnings: null,
        // From package:pkg_error1/pkg_error1.dart only:
        warnings: 1,
        hints: 1 + 1 /* from summary */,
        infos: 1);
    await test(Uri.parse('package:pkg_noerror/pkg_noerror.dart'),
        showPackageWarnings: [],
        // From package:pkg_error1 and package:pkg_error2:
        warnings: 2,
        hints: 2,
        infos: 2);
    await test(Uri.parse('package:pkg_noerror/pkg_noerror.dart'),
        showPackageWarnings: ['pkg_error1'],
        // From package:pkg_error1:
        warnings: 1,
        hints: 1 + 1 /* from summary */,
        infos: 1);
    await test(Uri.parse('package:pkg_noerror/pkg_noerror.dart'),
        showPackageWarnings: null, hints: 2 /* from summary */);
  });
}
