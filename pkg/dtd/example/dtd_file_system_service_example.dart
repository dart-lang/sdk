// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dtd/dtd.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  final url = args[0]; // pass the url as a param to the example

  // The directory to run in is passed as the 2nd argument to this example.
  final workingDirectory = Directory.fromUri(Uri.parse(args[1]));

  // Create the client that will be talking to the FileSystem service..
  DTDConnection? client = await DartToolingDaemon.connect(Uri.parse(url));

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
