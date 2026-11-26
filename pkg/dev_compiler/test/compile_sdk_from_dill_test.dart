// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dev_compiler/src/command/command.dart';
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Verifies the source map of an SDK compiled from a .dill file with
/// `--multi-root-output-path`, like the SDK build does (see `ddc_compile_sdk`
/// in utils/ddc/BUILD.gn).
void main() {
  test('source locations are relative to --multi-root-output-path', () async {
    final outDir = Directory.systemTemp.createTempSync('ddc_sdk_from_dill');
    addTearDown(() => outDir.deleteSync(recursive: true));
    final sdkJsPath = p.join(outDir.path, 'dart_sdk.js');
    final platformDill = computePlatformBinariesLocation(forceBuildDir: true)
        .resolve('ddc_platform.dill');

    final result = await compileSdkFromDill([
      '--modules',
      'ddc',
      '-o',
      sdkJsPath,
      '--multi-root-scheme',
      'org-dartlang-sdk',
      // A file path next to the source map, so the locations don't need to
      // leave its directory.
      '--multi-root-output-path',
      p.join(outDir.path, 'dart-sdk'),
      platformDill.toFilePath(),
    ]);
    expect(result.exitCode, 0);

    final sourceMap = jsonDecode(
      File('$sdkJsPath.map').readAsStringSync(),
    ) as Map<String, Object?>;
    final sources = (sourceMap['sources'] as List<Object?>).cast<String>();
    expect(sources, isNotEmpty);
    expect(sources, everyElement(startsWith('dart-sdk/lib/')));
  }, timeout: const Timeout.factor(4));
}
