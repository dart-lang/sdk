// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;

String get linterPackageRoot => path.joinAll(_packageRoot);

List<String> get _packageRoot {
  // Locate the root of the package without using `Platform.script` as it fails
  // when run through the `dart test`.
  // https://github.com/dart-lang/test/issues/110
  var packageLibUri = Isolate.resolvePackageUriSync(
    Uri.parse('package:linter/'),
  );

  var parts = path.split(path.dirname(packageLibUri!.toFilePath()));
  while (parts.last != 'linter') {
    parts.removeLast();
    if (parts.isEmpty) {
      throw StateError(
        "Script is not located inside a 'linter' directory? "
        "'${Platform.script.path}'",
      );
    }
  }
  return parts;
}

String pathRelativeToPackageRoot(Iterable<String> parts) =>
    path.joinAll([..._packageRoot, ...parts]);

String pathRelativeToPkgDir(Iterable<String> parts) {
  var pathParts = _packageRoot;
  pathParts.replaceRange(pathParts.length - 1, pathParts.length, parts);
  return path.joinAll(pathParts);
}
