// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that duplicate library names result in different messages depending
// on whether the libraries are based on the same resource.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'memory_compiler.dart';

void check(String kind,
           Iterable<DiagnosticMessage> messages,
           List<String> prefixes) {
  Expect.equals(messages.length, prefixes.length,
      "Unexpected $kind count: $messages");
  int i = 0;
  messages.forEach((DiagnosticMessage message) {
    Expect.isTrue(message.message.startsWith(prefixes[i++]));
  });
}

void test(Map<String, String> source,
          {List<String> warnings: const <String>[],
           List<String> hints: const <String>[]}) {
  DiagnosticCollector collector = new DiagnosticCollector();
  var compiler = compilerFor(source,
                             diagnosticHandler: collector,
                             showDiagnostics: true,
                             options: ['--analyze-only', '--analyze-all'],
                             packageRoot: Uri.parse('memory:pkg/'));
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    Expect.isTrue(collector.errors.isEmpty);
    check('warning', collector.warnings, warnings);
    check('hint', collector.hints, hints);
    Expect.isTrue(collector.infos.isEmpty);
  }));
}

void main() {
  test({
    'main.dart': """
library main;

import 'package:lib/foo.dart';
import 'pkg/lib/foo.dart';
""",
    'pkg/lib/foo.dart': """
library lib.foo;
"""},
    warnings: ["The library 'lib.foo' in 'memory:pkg/lib/foo.dart' is loaded"]);

  test({
    'main.dart': """
library main;

import 'package:lib/bar.dart';
import 'pkg/foo.dart';
""",
    'pkg/foo.dart': """
library foo;

import 'lib/bar.dart';
""",
    'pkg/lib/bar.dart': """
library lib.bar;
"""},
    warnings: ["The library 'lib.bar' in 'memory:pkg/lib/bar.dart' is loaded"]);

  test({
    'main.dart': """
library main;

import 'foo.dart';
import 'pkg/lib/baz.dart';
""",
    'foo.dart': """
library foo;

import 'package:lib/baz.dart';
""",
    'pkg/lib/baz.dart': """
library lib.baz;
"""},
    warnings: ["The library 'lib.baz' in 'memory:pkg/lib/baz.dart' is loaded"]);

  test({
    'main.dart': """
library main;

import 'foo.dart';
import 'pkg/bar.dart';
""",
    'foo.dart': """
library foo;

import 'package:lib/boz.dart';
""",
    'pkg/bar.dart': """
library bar;

import 'lib/boz.dart';
""",
    'pkg/lib/boz.dart': """
library lib.boz;
"""},
    warnings: ["The library 'lib.boz' in 'memory:pkg/lib/boz.dart' is loaded"]);

 test({
    'main.dart': """
library main;

import 'package:lib/qux.dart';
import 'pkg/lib/qux.dart';
""",
    'pkg/lib/qux.dart': """
// No library tag.
"""},
    hints: ["The resource 'memory:pkg/lib/qux.dart' is loaded"]);

  test({
    'main.dart': """
library main;

import 'foo.dart';
import 'bar.dart';
""",
    'foo.dart': """
library lib;
""",
    'bar.dart': """
library lib;
"""},
    warnings: ["Duplicated library name 'lib'.",
               "Duplicated library name 'lib'."]);
}

