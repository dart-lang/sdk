// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that duplicate library names result in different messages depending
// on whether the libraries are based on the same resource.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/diagnostics/messages.dart' show MessageKind;
import 'memory_compiler.dart';

void check(String kind,
           Iterable<DiagnosticMessage> messages,
           List<MessageKind> expectedMessageKinds) {
  Expect.equals(messages.length, expectedMessageKinds.length,
      "Unexpected $kind count: $messages");
  int i = 0;
  messages.forEach((DiagnosticMessage message) {
    Expect.equals(expectedMessageKinds[i++], message.message.kind);
  });
}

Future test(Map<String, String> source,
            {List<MessageKind> warnings: const <MessageKind>[],
            List<MessageKind> hints: const <MessageKind>[]}) async {
  DiagnosticCollector collector = new DiagnosticCollector();
  await runCompiler(
      memorySourceFiles: source,
      diagnosticHandler: collector,
      showDiagnostics: true,
      options: ['--analyze-only', '--analyze-all'],
      packageRoot: Uri.parse('memory:pkg/'));

  Expect.isTrue(collector.errors.isEmpty);
  check('warning', collector.warnings, warnings);
  check('hint', collector.hints, hints);
  Expect.isTrue(collector.infos.isEmpty);
}

void main() {
  asyncTest(runTests);
}

Future runTests() async {
  await test({
    'main.dart': """
library main;

import 'package:lib/foo.dart';
import 'pkg/lib/foo.dart';
""",
    'pkg/lib/foo.dart': """
library lib.foo;
"""},
    warnings: [MessageKind.DUPLICATED_LIBRARY_RESOURCE]);

  await test({
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
    warnings: [MessageKind.DUPLICATED_LIBRARY_RESOURCE]);

  await test({
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
    warnings: [MessageKind.DUPLICATED_LIBRARY_RESOURCE]);

  await test({
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
    warnings: [MessageKind.DUPLICATED_LIBRARY_RESOURCE]);

  await test({
    'main.dart': """
library main;

import 'package:lib/qux.dart';
import 'pkg/lib/qux.dart';
""",
    'pkg/lib/qux.dart': """
// No library tag.
"""},
    hints: [MessageKind.DUPLICATED_RESOURCE]);

  await test({
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
    warnings: [MessageKind.DUPLICATED_LIBRARY_NAME,
               MessageKind.DUPLICATED_LIBRARY_NAME]);
}

