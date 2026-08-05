// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import 'package:path/path.dart' as p;

/// Returns the path to the `dwds` package root directory.
Future<String> get dwdsPackageRoot async {
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:dwds/dwds.dart'),
  );
  if (uri == null) {
    throw StateError('Could not resolve package:dwds');
  }
  // uri is file:///.../pkg/dwds/lib/dwds.dart
  // We need to go up 2 levels to get to pkg/dwds
  return p.dirname(p.dirname(uri.toFilePath()));
}

/// Returns the absolute path to a file or directory relative to the `dwds`
/// package root.
Future<String> dwdsPath(String pathFromDwds) async {
  return p.normalize(p.join(await dwdsPackageRoot, pathFromDwds));
}
