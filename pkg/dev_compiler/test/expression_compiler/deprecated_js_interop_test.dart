// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that disabling deprecated JS interop makes `dart.library.*` conditions
/// for the deprecated libraries `false`, both in the compiled program and in
/// expressions evaluated in the debugger.
library;

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'expression_compiler_e2e_suite.dart';

const String _source = r'''
  void main() {
    var html = const bool.fromEnvironment('dart.library.html');
    var jsInterop = const bool.fromEnvironment('dart.library.js_interop');

    // Breakpoint: bp
    print('$html $jsInterop');
  }
''';

const String _importsDartHtmlSource = r'''
  import 'dart:html' as html;

  void main() {
    // Breakpoint: bp
    print('${html.window}');
  }
''';

void main(List<String> args) async {
  final driver = await ExpressionEvaluationTestDriver.init();

  tearDownAll(() async {
    await driver.finish();
  });

  for (final deprecatedJsInterop in [true, false]) {
    final mode = deprecatedJsInterop ? 'enabled' : 'disabled';
    group('deprecated JS interop $mode |', () {
      final setup = SetupCompilerOptions(
        moduleFormat: ModuleFormat.ddc,
        args: args,
        deprecatedJsInterop: deprecatedJsInterop,
      );

      setUpAll(() => driver.initSource(setup, _source));
      tearDownAll(() => driver.cleanupTest());

      test('dart.library.html in the program', () async {
        await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'html',
          expectedResult: '$deprecatedJsInterop',
        );
      });

      test('dart.library.html in an evaluated expression', () async {
        await driver.checkInFrame(
          breakpointId: 'bp',
          expression: "const bool.fromEnvironment('dart.library.html')",
          expectedResult: '$deprecatedJsInterop',
        );
      });

      test('dart.library.js_interop is unaffected', () async {
        await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'jsInterop',
          expectedResult: 'true',
        );
      });
    });
  }

  test('html import is accessible when flag is enabled', () async {
    final setup = SetupCompilerOptions(
      moduleFormat: ModuleFormat.ddc,
      args: args,
      deprecatedJsInterop: true,
    );

    await driver.initSource(setup, _importsDartHtmlSource);

    await driver.checkInFrame(
      breakpointId: 'bp',
      expression: 'html.window.scrollX',
      expectedResult: '0',
    );
  });

  test('compilation fails when flag is disabled', () async {
    final setup = SetupCompilerOptions(
      moduleFormat: ModuleFormat.ddc,
      args: args,
      deprecatedJsInterop: false,
    );
    expect(driver.initSource(setup, _importsDartHtmlSource), throwsException);
  });
}
