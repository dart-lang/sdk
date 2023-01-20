// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:path/path.dart' as p;
import 'package:source_maps/source_maps.dart' as sm;

void main() async {
  // This test relies on source maps for the built SDK when working inside the
  // Dart SDK repo.
  final buildDir = computePlatformBinariesLocation(forceBuildDir: true);
  final sdkJsMapDir = buildDir
      .resolve(p.joinAll(['gen', 'utils', 'dartdevc', 'sound', 'amd']))
      .toFilePath();
  final sdkJsMapFile = p.join(sdkJsMapDir, 'dart_sdk.js.map');

  final sdkJsMapText = await File(sdkJsMapFile).readAsString();
  var mapping = sm.parse(sdkJsMapText) as sm.SingleMapping;

  var urls = mapping.urls;
  Expect.isTrue(urls.isNotEmpty);
  for (var url in urls) {
    Expect.equals(p.extension(url), '.dart');
    Expect.isFalse(p.isAbsolute(url));
    var fullPath = p.canonicalize(p.join(sdkJsMapDir, url));
    Expect.isTrue(await File(fullPath).exists(), 'Missing file: $fullPath');
  }
}
