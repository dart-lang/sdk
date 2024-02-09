// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;

import 'binary_md_dill_reader.dart' show BinaryMdDillReader;

import 'utils/io_utils.dart' show computeRepoDir;

Future<void> main() async {
  File binaryMd = new File("$repoDir/pkg/kernel/binary.md");
  String binaryMdContent = binaryMd.readAsStringSync();

  BinaryMdDillReader binaryMdDillReader =
      new BinaryMdDillReader(binaryMdContent, const <int>[]);
  binaryMdDillReader.setup();

  List<String> errors = [];
  binaryMdDillReader.readingInstructions.forEach((clazz, fields) {
    if (binaryMdDillReader.isA(clazz, "Expression") &&
        !binaryMdDillReader.isAbstract(clazz)) {
      bool foundOffset = false;
      for (String field in fields) {
        if (field == 'FileOffset fileOffset;') {
          foundOffset = true;
          break;
        }
      }
      if (!foundOffset) {
        errors.add("$clazz missing required field 'fileOffset'.");
      }
    }
  });

  if (errors.isNotEmpty) {
    throw Exception(
        'Found the following errors with binary.md: ${errors.join('\n')}');
  }
}

final String repoDir = computeRepoDir();
