// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:path/path.dart' as p;
import 'package:source_maps/source_maps.dart' as sm;

/// Verifies that the compiled SDK modules used in the SDK test suites have
/// source maps, and those mappings correctly point to the .dart source files.
///
/// Also checks the precompiled SDK modules packaged in the Dart SDK.
void main() async {
  // This test relies on source maps for the built SDK when working inside the
  // Dart SDK repo.
  final buildDir = computePlatformBinariesLocation(forceBuildDir: true);
  final sdkDir = buildDir.resolve('dart-sdk/');
  for (final sdkJsMapFile in [
    buildDir.resolve('gen/utils/ddc/stable/sdk/amd/dart_sdk.js.map'),
    for (final version in ['canary', 'stable'])
      sdkDir.resolve('lib/dev_compiler/$version/sdk/dart_sdk.js.map'),
  ]) {
    final sdkJsMapText = await File.fromUri(sdkJsMapFile).readAsString();
    var mapping = sm.parse(sdkJsMapText) as sm.SingleMapping;

    // Tools serve the SDK modules and their source maps at the web root and
    // the SDK at /dart-sdk/, so the source map locations are dart-sdk/lib/...
    var urls = mapping.urls;
    Expect.isTrue(urls.isNotEmpty);
    for (var url in urls) {
      Expect.equals(p.extension(url), '.dart');
      Expect.isTrue(url.startsWith('dart-sdk/lib/'), 'Unexpected path: $url');
      Expect.isFalse(url.contains('..'), 'Unexpected path: $url');
      var file = File.fromUri(
        sdkDir.resolve(url.substring('dart-sdk/'.length)),
      );
      Expect.isTrue(await file.exists(), 'Missing file: ${file.path}');
    }
  }
}
