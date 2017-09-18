// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@string
@symbol
library test.library_metadata_test;

import 'dart:mirrors';

import 'metadata_test.dart';

main() {
  MirrorSystem mirrors = currentMirrorSystem();
  checkMetadata(
      mirrors.findLibrary(#test.library_metadata_test), [string, symbol]);
  checkMetadata(mirrors.findLibrary(#test.metadata_test), []);
}
