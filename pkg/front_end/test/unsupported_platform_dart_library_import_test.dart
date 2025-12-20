// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:_fe_analyzer_shared/src/messages/diagnostic_message.dart"
    show CfeDiagnosticMessage, getMessageCodeObject, getMessageArguments;
import 'package:dev_compiler/dev_compiler.dart';
import 'package:expect/async_helper.dart' show asyncTest;
import 'package:expect/expect.dart' show Expect;
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:front_end/src/codes/cfe_codes.dart'
    show codeUnsupportedPlatformDartLibraryImport, codeUnavailableDartLibrary;
import 'package:front_end/src/testing/compiler_common.dart' show compileScript;
import 'package:kernel/target/targets.dart';

const String testSource = '''
import 'dart:async';
import 'dart:ffi';
import 'dart:html';
import 'dart:io';
import 'dart:isolate';

main() {}
''';

/// Check that a warning is reported for imports of platform-specific dart:*
/// libraries when includeUnsupportedPlatformLibraryStubs is true.
Future<void> testUnsupportedPlatformImportWarning() async {
  var unsupportedLibraryUris = <String>[];
  var options = new CompilerOptions()
    ..sdkSummary = computePlatformBinariesLocation().resolve(
      'ddc_platform.dill',
    )
    ..target = DevCompilerTarget(
      TargetFlags(includeUnsupportedPlatformLibraryStubs: true),
    )
    ..onDiagnostic = (CfeDiagnosticMessage message) {
      Expect.equals(CfeSeverity.warning, message.severity);
      Expect.identical(
        codeUnsupportedPlatformDartLibraryImport,
        getMessageCodeObject(message),
      );
      Expect.isTrue(message.plainTextFormatted.length == 1);
      unsupportedLibraryUris.add(
        getMessageArguments(message)!['uri'].toString(),
      );
    }
    ..environmentDefines = {};
  await compileScript(testSource, options: options);
  Expect.listEquals(unsupportedLibraryUris, ['dart:ffi']);
}

/// Check that an error is reported for imports of platform-specific dart:*
/// libraries when includeUnsupportedPlatformLibraryStubs is false.
Future<void> testUnsupportedPlatformImportError() async {
  var unsupportedLibraryUris = <String>[];
  var options = new CompilerOptions()
    ..sdkSummary = computePlatformBinariesLocation().resolve(
      'ddc_platform.dill',
    )
    ..target = DevCompilerTarget(TargetFlags())
    ..onDiagnostic = (CfeDiagnosticMessage message) {
      Expect.equals(CfeSeverity.error, message.severity);
      Expect.identical(
        codeUnavailableDartLibrary,
        getMessageCodeObject(message),
      );
      Expect.isTrue(message.plainTextFormatted.length == 1);
      unsupportedLibraryUris.add(
        getMessageArguments(message)!['uri'].toString(),
      );
    }
    ..environmentDefines = {};
  await compileScript(testSource, options: options);
  Expect.listEquals(unsupportedLibraryUris, ['dart:ffi']);
}

void main() {
  asyncTest(() async {
    await testUnsupportedPlatformImportWarning();
  });
  asyncTest(() async {
    await testUnsupportedPlatformImportError();
  });
}
