// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/services/expression_compiler.dart';
import 'package:dwds/src/services/expression_compiler_service.dart';
import 'package:test/test.dart';

void main() {
  group('expressionCompilerWorkerArgs', () {
    List<String> argsFor({bool? deprecatedJsInterop}) =>
        expressionCompilerWorkerArgs(
          sdkSummaryUri: Uri.file('/sdk/ddc_outline.dill'),
          address: 'localhost',
          port: 1234,
          compilerOptions: CompilerOptions(
            moduleFormat: ModuleFormat.ddc,
            canaryFeatures: true,
            experiments: const ['records'],
            deprecatedJsInterop: deprecatedJsInterop,
          ),
          verbose: false,
        );

    test('passes the compiler options', () {
      expect(argsFor(), [
        '--experimental-expression-compiler',
        '--dart-sdk-summary',
        'file:///sdk/ddc_outline.dill',
        '--asset-server-address',
        'localhost',
        '--asset-server-port',
        '1234',
        '--module-format',
        'ddc',
        '--enable-experiment=records',
        '--canary',
      ]);
    });

    test('does not pass deprecated-js-interop when not configured', () {
      expect(argsFor(), isNot(contains(contains('deprecated-js-interop'))));
    });

    test('passes --deprecated-js-interop', () {
      final args = argsFor(deprecatedJsInterop: true);
      expect(args, contains('--deprecated-js-interop'));
      expect(args, isNot(contains('--no-deprecated-js-interop')));
    });

    test('passes --no-deprecated-js-interop', () {
      final args = argsFor(deprecatedJsInterop: false);
      expect(args, contains('--no-deprecated-js-interop'));
      expect(args, isNot(contains('--deprecated-js-interop')));
    });
  });
}
