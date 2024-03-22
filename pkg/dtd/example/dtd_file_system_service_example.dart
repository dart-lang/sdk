// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dtd/dtd.dart';
import 'package:path/path.dart' as path;

/// IMPORTANT: the `dtdUrl` below should point to a Dart Tooling Daemon instance
/// that has been started with the --unrestricted flag:
/// ```sh
/// > dart tooling-daemon
/// The Dart Tooling Daemon is listening on ws://127.0.0.1:62925/cKB5QFiAUNMzSzlb
/// > dart run dtd_file_system_service_example.dart ws://127.0.0.1:62925/cKB5QFiAUNMzSzlb /path/to/a/test/directory
/// ```
void main(List<String> args) async {
  final dtdUrl = args[0]; // pass the url as a param to the example

  // The directory to run in is passed as the 2nd argument to this example.
  final workingDirectory = Directory.fromUri(Uri.parse(args[1]));

  final dtdSecret = args.length >= 3 ? args[2] : null;

  // Create the client that will be talking to the FileSystem service..
  DartToolingDaemon? client = await DartToolingDaemon.connect(
    Uri.parse(dtdUrl),
  );

  if (dtdSecret != null) {
    // If the dtd secret is passed as an argument, then set our example
    // directory as the ide workspace roots. This will ensure that there is
    // permission for the client to perform actions on that directory.
    await client.setIDEWorkspaceRoots(dtdSecret, [workingDirectory.uri]);
  }

  try {
    final testFile = Uri.file(path.join(workingDirectory.path, 'a.txt'));

    // Writing a file from a DTD client.
    await client.writeFileAsString(
      testFile,
      'Here are some file contents to write.',
    );

    // Reading a file from a DTD client.
    final fileContents = await client.readFileAsString(testFile);

    print(jsonEncode({'step': 'read', 'response': fileContents.toJson()}));

    // Listing directories from a DTD client.
    final listFilesResponse = await client.listDirectoryContents(
      workingDirectory.uri,
    );

    print(
      jsonEncode(
        {'step': 'listDirectories', 'response': listFilesResponse.toJson()},
      ),
    );
  } finally {
    await client.close();
  }
}
