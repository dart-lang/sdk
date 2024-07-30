// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "explicit_creation_impl.dart" show runExplicitCreationTest;
import 'testing_utils.dart' show getGitFiles;
import "utils/io_utils.dart" show computeRepoDirUri;

Future<void> main(List<String> args) async {
  final Uri repoDir = computeRepoDirUri();

  Set<Uri> libUris = {};

  if (args.isEmpty) {
    libUris.add(repoDir.resolve("pkg/front_end/lib/"));
    libUris.add(repoDir.resolve("pkg/_fe_analyzer_shared/lib/"));
    libUris.add(repoDir.resolve("pkg/frontend_server/"));
  } else {
    for (String arg in args) {
      if (arg == "--front-end-only") {
        libUris.add(repoDir.resolve("pkg/front_end/lib/"));
      } else if (arg == "--shared-only") {
        libUris.add(repoDir.resolve("pkg/_fe_analyzer_shared/lib/"));
      } else if (arg == "--frontend_server-only") {
        libUris.add(repoDir.resolve("pkg/frontend_server/"));
      } else {
        throw "Unsupported arguments: $args";
      }
    }
  }

  Set<Uri> inputs = {};
  for (Uri uri in libUris) {
    Set<Uri> gitFiles = await getGitFiles(uri);
    List<FileSystemEntity> entities =
        new Directory.fromUri(uri).listSync(recursive: true);
    for (FileSystemEntity entity in entities) {
      if (entity is File &&
          entity.path.endsWith(".dart") &&
          gitFiles.contains(entity.uri)) {
        inputs.add(entity.uri);
      }
    }
  }

  int explicitCreationErrorsFound = await runExplicitCreationTest(
      includedFiles: inputs, includedDirectoryUris: libUris, repoDir: repoDir);
  if (explicitCreationErrorsFound > 0) {
    exitCode = 1;
  }
}
