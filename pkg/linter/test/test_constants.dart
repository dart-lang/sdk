// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

final String integrationTestDir =
    pathRelativeToPackageRoot(['test_data', 'integration']);
final String ruleTestDataDir =
    pathRelativeToPackageRoot(['test_data', 'rules']);
final String ruleTestDir = pathRelativeToPackageRoot(['test', 'rules']);
final String testConfigDir = pathRelativeToPackageRoot(['test', 'configs']);

List<String> get _scriptPathParts =>
    path.split(path.dirname(path.fromUri(Platform.script.path)));

String pathRelativeToPackageRoot(Iterable<String> parts) {
  var pathParts = _scriptPathParts;
  pathParts.replaceRange(pathParts.length - 1, pathParts.length, parts);
  return path.joinAll(pathParts);
}

String pathRelativeToPkgDir(Iterable<String> parts) {
  var pathParts = _scriptPathParts;
  pathParts.replaceRange(pathParts.length - 2, pathParts.length, parts);
  return path.joinAll(pathParts);
}
