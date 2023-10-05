// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test to verify that this package is in-sync with shared runtime libraries.
library;

import 'dart:io';

import 'package:_fe_analyzer_shared/src/util/relativize.dart';
import 'package:expect/expect.dart';

void main(List<String> argv) {
  var packageDir = Platform.script.resolve('../lib/synced/');
  var sdkDir = Platform.script
      .resolve('../../../sdk/lib/_internal/js_shared/lib/synced/');
  var rPackageDir =
      relativizeUri(Directory.current.uri, packageDir, Platform.isWindows);
  var rSdkDir =
      relativizeUri(Directory.current.uri, sdkDir, Platform.isWindows);

  for (var file in Directory.fromUri(sdkDir).listSync()) {
    if (file is File) {
      var filename = file.uri.pathSegments.last;
      var packageFile = File.fromUri(packageDir.resolve(filename));
      Expect.isTrue(
          packageFile.existsSync(),
          "$filename not in sync. Please update it by running:\n"
          "  cp $rSdkDir$filename $rPackageDir$filename");
      var original = file.readAsBytesSync();
      var copy = packageFile.readAsBytesSync();
      Expect.listEquals(
          original,
          copy,
          "$filename not in sync. Please update it by running:\n"
          "  cp $rSdkDir$filename $rPackageDir$filename");
    }
  }
}
