// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that the helper [Compiler.inUserCode] works as intended.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/compiler.dart' show Compiler;
import '../helpers/memory_compiler.dart';

const SOURCE = const {
  'main.dart': """
library main;

import 'dart:async';
import 'foo.dart';
import 'pkg/sub/bar.dart';
import 'package:sub/bar.dart';
import 'package:sup/boz.dart';

main() {}
""",
  'foo.dart': """
library foo;
""",
  'pkg/sub/bar.dart': """
library sub.bar;

import 'package:sup/boz.dart';
import 'baz.dart';

main() {}
""",
  'pkg/sub/baz.dart': """
library sub.baz;
""",
  'pkg/sup/boz.dart': """
library sup.boz;
""",
  '.packages': """
sub:pkg/sub/
sup:pkg/sup/
"""
};

Future test(Uri entryPoint, Map<String, bool> expectedResults) async {
  print("Test: $entryPoint");
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: SOURCE,
      packageConfig: Uri.parse('memory:.packages'));
  Compiler compiler = result.compiler;
  expectedResults.forEach((String uri, bool expectedResult) {
    dynamic element = compiler.frontendStrategy.elementEnvironment
        .lookupLibrary(Uri.parse(uri));
    Expect.isNotNull(element, "Unknown library '$uri'.");
    Expect.equals(
        expectedResult,
        compiler.inUserCode(element),
        expectedResult
            ? "Library '$uri' expected to be in user code"
            : "Library '$uri' not expected to be in user code");
  });
}

void main() {
  asyncTest(runTests);
}

Future runTests() async {
  await test(Uri.parse('memory:main.dart'), {
    'memory:main.dart': true,
    'memory:foo.dart': true,
    'memory:pkg/sub/bar.dart': true,
    'memory:pkg/sub/baz.dart': true,
    'package:sub/bar.dart': false,
    'package:sub/baz.dart': false,
    'package:sup/boz.dart': false,
    'dart:core': false,
    'dart:async': false
  });
  await test(Uri.parse('package:sub/bar.dart'), {
    'package:sub/bar.dart': true,
    'package:sub/baz.dart': true,
    'package:sup/boz.dart': false,
    'dart:core': false
  });
}
