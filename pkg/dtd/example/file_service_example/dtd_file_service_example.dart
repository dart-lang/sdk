// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dtd/dtd.dart';
import 'package:dtd/dtd_file_system_extension.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  final url = args[0]; // pass the url as a param to the example

  print('Connecting to DTD at $url');

  final client = await DartToolingDaemon.connect(Uri.parse('ws://$url'));
  final directory = Directory('/tmp/dtd_file_service_example');
  if (!directory.existsSync()) {
    directory.createSync();
  }
  final directoryUri = directory.uri;

  final testFile = Uri.file(path.join(directory.path, 'a.txt'));

  final now = DateTime.now().toLocal().toIso8601String();

  await client.writeFileAsString(testFile, now);
  print('Wrote "$now" to $testFile');

  final fileContents = await client.readFileAsString(testFile);
  print('\nThe Contents of $testFile are:\n${fileContents.content}');

  final listFilesResponse = await client.listDirectories(
    directoryUri,
  );
  print(
    '\nThe files in $directoryUri are:\n'
    '${listFilesResponse?.uris?.join('\n')}',
  );
}
