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
  }).then(asyncSuccess);
}

main() {
  runCompiler(
    "",
    [],
    (String code, List errors, List warnings) {
      Expect.isNull(code);
      Expect.equals(1, errors.length, 'errors=$errors');
      Expect.equals("Could not find 'main'.", errors[0].toString());
      Expect.isTrue(warnings.isEmpty, 'warnings=$warnings');
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
      Expect.equals(1, errors.length);
      Expect.isTrue(
          errors[0].toString().startsWith("Could not find 'main'."));
      Expect.isTrue(warnings.isEmpty);
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
      Expect.equals(1, errors.length);
      Expect.isTrue(
          errors[0].toString().startsWith("Could not find 'main'."));
      Expect.isTrue(warnings.isEmpty);
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
