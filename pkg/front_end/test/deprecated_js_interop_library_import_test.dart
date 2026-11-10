// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:_fe_analyzer_shared/src/messages/diagnostic_message.dart"
    show CfeDiagnosticMessage, getMessageCodeObject, getMessageArguments;
import 'package:dev_compiler/dev_compiler.dart';
import 'package:expect/async_helper.dart' show asyncTest;
import 'package:expect/expect.dart' show Expect;
import 'package:front_end/src/api_unstable/ddc.dart';

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:front_end/src/testing/compiler_common.dart' show compileScript;
import 'package:kernel/target/targets.dart';

const String testSource = '''
import 'dart:html';
import 'dart:js_interop';
import 'dart:js_util';

main() {}
''';

/// Compiles [testSource] for DDC and returns the diagnostics reported.
Future<List<CfeDiagnosticMessage>> compile({
  required bool deprecatedJsInterop,
}) async {
  List<CfeDiagnosticMessage> diagnostics = [];
  CompilerOptions options = new CompilerOptions()
    ..sdkSummary = computePlatformBinariesLocation().resolve(
      'ddc_platform.dill',
    )
    ..target = new DevCompilerTarget(
      new TargetFlags(),
      deprecatedJsInterop: deprecatedJsInterop,
    )
    ..onDiagnostic = diagnostics.add
    ..environmentDefines = {};
  await compileScript(testSource, options: options);
  return diagnostics;
}

/// Check that an error is reported for each import of a deprecated
/// JS interop library when deprecated JS interop is disabled.
Future<void> testDeprecatedJsInteropDisabled() async {
  List<CfeDiagnosticMessage> diagnostics = await compile(
    deprecatedJsInterop: false,
  );
  for (CfeDiagnosticMessage message in diagnostics) {
    Expect.equals(CfeSeverity.error, message.severity);
    Expect.identical(
      diag.deprecatedJsInteropLibraryImport,
      getMessageCodeObject(message),
    );
  }
  Expect.listEquals(
    ['dart:html', 'dart:js_util'],
    diagnostics
        .map((message) => getMessageArguments(message)!['uri'].toString())
        .toList(),
  );
}

/// Check that no errors are reported for imports of deprecated JS interop
/// libraries when deprecated JS interop is enabled.
Future<void> testDeprecatedJsInteropEnabled() async {
  List<CfeDiagnosticMessage> diagnostics = await compile(
    deprecatedJsInterop: true,
  );
  Expect.isTrue(diagnostics.isEmpty, '$diagnostics');
}

void main() {
  asyncTest(() async {
    await testDeprecatedJsInteropDisabled();
    await testDeprecatedJsInteropEnabled();
  });
}
