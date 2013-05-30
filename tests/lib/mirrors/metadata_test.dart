// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@fisk @symbol
library test.metadata_test;

import 'dart:mirrors';

const fisk = 'a metadata string';

const symbol = const Symbol('fisk');

main() {
  MirrorSystem mirrors = currentMirrorSystem();
  LibraryMirror library =
      mirrors.findLibrary(const Symbol('test.metadata_test')).first;
  List metadata = library.metadata.map((m) => m.reflectee).toList();
  if (metadata.length != 2) {
    throw 'Expected two pieces of metadata on library';
  }
  if (!metadata.contains(fisk)) {
    throw '$metadata does not contain "$fisk"';
  }
  if (!metadata.contains(symbol)) {
    throw '$metadata does not contain "$symbol"';
  }
  if (MirrorSystem.getName(symbol) != 'fisk') {
    // This happened in dart2js due to how early library metadata is
    // computed.
    throw 'Bad constant: $symbol';
  }
  print(metadata);
}
