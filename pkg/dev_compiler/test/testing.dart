// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.testing;

import 'dart:mirrors';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as path;

final String testingPath =
    path.fromUri((reflectClass(_TestUtils).owner as LibraryMirror).uri);
final String testDirectory = path.dirname(testingPath);

/// The local path to the root directory of the dev_compiler repo.
final String repoDirectory = path.dirname(testDirectory);

class _TestUtils {}

class TestUriResolver extends ResourceUriResolver {
  final MemoryResourceProvider provider;
  TestUriResolver(provider)
      : provider = provider,
        super(provider);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (uri.scheme == 'package') {
      return (provider.getResource('/packages/' + uri.path) as File)
          .createSource(uri);
    }
    return super.resolveAbsolute(uri, actualUri);
  }
}
