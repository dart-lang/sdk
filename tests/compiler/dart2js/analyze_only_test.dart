// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Smoke test of the dart2js compiler API.
library analyze_only;

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/diagnostics/messages.dart'
    show MessageKind, MessageTemplate;
import 'package:compiler/src/old_to_new_api.dart';
import 'package:compiler/src/options.dart';

import 'dummy_compiler_test.dart' as dummy;
import 'output_collector.dart';

runCompiler(String main, List<String> options,
    onValue(String code, List errors, List warnings)) {
  List errors = new List();
  List warnings = new List();

  Future<String> localProvider(Uri uri) {
    if (uri.scheme != 'main') return dummy.provider(uri);
    return new Future<String>.value(main);
  }

  void localHandler(
      Uri uri, int begin, int end, String message, Diagnostic kind) {
    dummy.handler(uri, begin, end, message, kind);
    if (kind == Diagnostic.ERROR) {
      errors.add(message);
    } else if (kind == Diagnostic.WARNING) {
      warnings.add(message);
    }
  }

  print('-----------------------------------------------');
  print('main source:\n$main');
  print('options: $options\n');
  asyncStart();
  OutputCollector outputCollector = new OutputCollector();
  Future<CompilationResult> result = compile(
      new CompilerOptions.parse(
          entryPoint: new Uri(scheme: 'main'),
          libraryRoot: new Uri(scheme: 'lib', path: '/'),
          packageRoot: new Uri(scheme: 'package', path: '/'),
          options: options),
      new LegacyCompilerInput(localProvider),
      new LegacyCompilerDiagnostics(localHandler),
      outputCollector);
  result
      .then((_) {
        onValue(outputCollector.getOutput('', OutputType.js), errors, warnings);
      }, onError: (e, st) {
        throw 'Compilation failed: ${e} ${st}';
      })
      .then(asyncSuccess)
      .catchError((error, stack) {
        print('\n\n-----------------------------------------------');
        print('main source:\n$main');
        print('options: $options\n');
        print('threw:\n $error\n$stack');
        print('-----------------------------------------------\n\n');
        throw error;
      });
}

main() {
  runCompiler("", [Flags.generateCodeWithCompileTimeErrors],
      (String code, List errors, List warnings) {
    Expect.isNotNull(code);
    Expect.isTrue(errors.isEmpty, 'errors is not empty: $errors');
    MessageTemplate template =
        MessageTemplate.TEMPLATES[MessageKind.MISSING_MAIN];
    Expect.equals("${template.message({'main': 'main'})}", warnings.single);
  });

  runCompiler("main() {}", [Flags.generateCodeWithCompileTimeErrors],
      (String code, List errors, List warnings) {
    Expect.isNotNull(code);
    Expect.isTrue(errors.isEmpty);
    Expect.isTrue(warnings.isEmpty);
  });

  runCompiler("", [Flags.analyzeOnly],
      (String code, List errors, List warnings) {
    Expect.isNull(code);
    Expect.isTrue(errors.isEmpty, 'errors is not empty: $errors');
    MessageTemplate template =
        MessageTemplate.TEMPLATES[MessageKind.CONSIDER_ANALYZE_ALL];
    Expect.equals("${template.message({'main': 'main'})}", warnings.single);
  });

  runCompiler("main() {}", [Flags.analyzeOnly],
      (String code, List errors, List warnings) {
    Expect.isNull(code);
    Expect.isTrue(errors.isEmpty);
    Expect.isTrue(warnings.isEmpty);
  });

  runCompiler("Foo foo; // Unresolved but not analyzed.", [Flags.analyzeOnly],
      (String code, List errors, List warnings) {
    Expect.isNull(code);
    Expect.isTrue(errors.isEmpty, 'errors is not empty: $errors');
    MessageTemplate template =
        MessageTemplate.TEMPLATES[MessageKind.CONSIDER_ANALYZE_ALL];
    Expect.equals("${template.message({'main': 'main'})}", warnings.single);
  });

  runCompiler(
      """main() {
         Foo foo; // Unresolved and analyzed.
       }""",
      [Flags.analyzeOnly], (String code, List errors, List warnings) {
    Expect.isNull(code);
    Expect.isTrue(errors.isEmpty);
    Expect.equals(1, warnings.length);
    Expect.equals("Cannot resolve type 'Foo'.", warnings[0].toString());
  });

  runCompiler(
      """main() {
         Foo foo; // Unresolved and analyzed.
       }""",
      [Flags.analyzeOnly, Flags.analyzeSignaturesOnly],
      (String code, List errors, List warnings) {
    Expect.isNull(code);
    Expect.isTrue(errors.isEmpty);
    Expect.isTrue(warnings.isEmpty);
  });

  runCompiler("Foo foo; // Unresolved and analyzed.", [
    Flags.analyzeOnly,
    Flags.analyzeAll
  ], (String code, List errors, List warnings) {
    Expect.isNull(code);
    Expect.isTrue(errors.isEmpty);
    Expect.equals("Cannot resolve type 'Foo'.", warnings[0].toString());
  });

  runCompiler(
      """Foo foo; // Unresolved and analyzed.
       main() {}""",
      [Flags.analyzeOnly, Flags.analyzeAll],
      (String code, List errors, List warnings) {
    Expect.isNull(code);
    Expect.isTrue(errors.isEmpty, 'Unexpected errors: $errors.');
    Expect.equals(1, warnings.length, 'Unexpected warning count: $warnings.');
    Expect.equals("Cannot resolve type 'Foo'.", warnings[0].toString());
  });

  runCompiler("", [Flags.analyzeOnly, Flags.analyzeAll],
      (String code, List errors, List warnings) {
    Expect.isNull(code);
    Expect.isTrue(errors.isEmpty);
    Expect.isTrue(warnings.isEmpty);
  });

  // --analyze-signatures-only implies --analyze-only
  runCompiler("", [Flags.analyzeSignaturesOnly, Flags.analyzeAll],
      (String code, List errors, List warnings) {
    Expect.isNull(code);
    Expect.isTrue(errors.isEmpty);
    Expect.isTrue(warnings.isEmpty);
  });

  // Test that --allow-native-extensions works.
  runCompiler(
      """main() {}
      foo() native 'foo';""",
      [Flags.analyzeOnly, Flags.allowNativeExtensions],
      (String code, List errors, List warnings) {
    Expect.isNull(code);
    Expect.isTrue(errors.isEmpty);
    Expect.isTrue(warnings.isEmpty);
  });
  runCompiler(
      """main() {}
      foo() native 'foo';""",
      [Flags.analyzeOnly], (String code, List errors, List warnings) {
    Expect.isNull(code);
    Expect.isTrue(
        errors.single.startsWith("'native' modifier is not supported."));
    Expect.isTrue(warnings.isEmpty);
  });
}
