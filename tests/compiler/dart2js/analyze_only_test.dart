// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Smoke test of the dart2js compiler API.
library analyze_only;

import "package:expect/expect.dart";
import 'dart:async';
import "package:async_helper/async_helper.dart";

import '../../utils/dummy_compiler_test.dart' as dummy;
import 'package:compiler/compiler.dart';

import 'package:compiler/implementation/dart2jslib.dart' show
    MessageKind;

runCompiler(String main, List<String> options,
            onValue(String code, List errors, List warnings)) {
  List errors = new List();
  List warnings = new List();

  Future<String> localProvider(Uri uri) {
    if (uri.scheme != 'main') return dummy.provider(uri);
    return new Future<String>.value(main);
  }

  void localHandler(Uri uri, int begin, int end,
                    String message, Diagnostic kind) {
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
  Future<String> result =
      compile(new Uri(scheme: 'main'),
              new Uri(scheme: 'lib', path: '/'),
              new Uri(scheme: 'package', path: '/'),
              localProvider, localHandler, options);
  result.then((String code) {
    onValue(code, errors, warnings);
  }, onError: (e) {
    throw 'Compilation failed: ${Error.safeToString(e)}';
  }).then(asyncSuccess).catchError((error, stack) {
    print('\n\n-----------------------------------------------');
    print('main source:\n$main');
    print('options: $options\n');
    print('threw:\n $error\n$stack');
    print('-----------------------------------------------\n\n');
    throw error;
  });
}

main() {
  runCompiler(
    "",
    [],
    (String code, List errors, List warnings) {
      Expect.isNotNull(code);
      Expect.isTrue(errors.isEmpty, 'errors is not empty: $errors');
      Expect.equals(
          "${MessageKind.MISSING_MAIN.message({'main': 'main'})}",
          warnings.single);
    });

  runCompiler(
    "main() {}",
    [],
    (String code, List errors, List warnings) {
      Expect.isNotNull(code);
      Expect.isTrue(errors.isEmpty);
      Expect.isTrue(warnings.isEmpty);
    });

  runCompiler(
    "",
    ['--analyze-only'],
    (String code, List errors, List warnings) {
      Expect.isNull(code);
      Expect.isTrue(errors.isEmpty, 'errors is not empty: $errors');
      Expect.equals(
          "${MessageKind.CONSIDER_ANALYZE_ALL.message({'main': 'main'})}",
          warnings.single);
    });

  runCompiler(
    "main() {}",
    ['--analyze-only'],
    (String code, List errors, List warnings) {
      Expect.isNull(code);
      Expect.isTrue(errors.isEmpty);
      Expect.isTrue(warnings.isEmpty);
    });

  runCompiler(
    "Foo foo; // Unresolved but not analyzed.",
    ['--analyze-only'],
    (String code, List errors, List warnings) {
      Expect.isNull(code);
      Expect.isTrue(errors.isEmpty, 'errors is not empty: $errors');
      Expect.equals(
          "${MessageKind.CONSIDER_ANALYZE_ALL.message({'main': 'main'})}",
          warnings.single);
    });

  runCompiler(
    """main() {
         Foo foo; // Unresolved and analyzed.
       }""",
    ['--analyze-only'],
    (String code, List errors, List warnings) {
      Expect.isNull(code);
      Expect.isTrue(errors.isEmpty);
      Expect.equals(1, warnings.length);
      Expect.equals(
          "Cannot resolve type 'Foo'.", warnings[0].toString());
    });

  runCompiler(
    """main() {
         Foo foo; // Unresolved and analyzed.
       }""",
    ['--analyze-only', '--analyze-signatures-only'],
    (String code, List errors, List warnings) {
      Expect.isNull(code);
      Expect.isTrue(errors.isEmpty);
      Expect.isTrue(warnings.isEmpty);
    });

  runCompiler(
    "Foo foo; // Unresolved and analyzed.",
    ['--analyze-only', '--analyze-all'],
    (String code, List errors, List warnings) {
      Expect.isNull(code);
      Expect.isTrue(errors.isEmpty);
      Expect.equals(
          "Cannot resolve type 'Foo'.", warnings[0].toString());
    });

  runCompiler(
    """Foo foo; // Unresolved and analyzed.
       main() {}""",
    ['--analyze-only', '--analyze-all'],
    (String code, List errors, List warnings) {
      Expect.isNull(code);
      Expect.isTrue(errors.isEmpty, 'Unexpected errors: $errors.');
      Expect.equals(1, warnings.length, 'Unexpected warning count: $warnings.');
      Expect.equals(
          "Cannot resolve type 'Foo'.", warnings[0].toString());
    });

  runCompiler(
    "",
    ['--analyze-only', '--analyze-all'],
    (String code, List errors, List warnings) {
      Expect.isNull(code);
      Expect.isTrue(errors.isEmpty);
      Expect.isTrue(warnings.isEmpty);
    });

  // --analyze-signatures-only implies --analyze-only
  runCompiler(
    "",
    ['--analyze-signatures-only', '--analyze-all'],
    (String code, List errors, List warnings) {
      Expect.isNull(code);
      Expect.isTrue(errors.isEmpty);
      Expect.isTrue(warnings.isEmpty);
    });
}
