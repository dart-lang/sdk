// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;

import '../test/binary_md_dill_reader.dart' show BinaryMdDillReader;
import '../test/utils/io_utils.dart' show computeRepoDir;

void main() {
  File binaryMd = new File("$repoDir/pkg/kernel/binary.md");
  String binaryMdContent = binaryMd.readAsStringSync();

  BinaryMdDillReader binaryMdReader =
      new BinaryMdDillReader(binaryMdContent, []);
  binaryMdReader.setup();

  for (int i = 0; i < 256; i++) {
    if (!binaryMdReader.tagToName.containsKey(i)) {
      print("Tag $i is free.");
    }
  }
}

final String repoDir = computeRepoDir();
