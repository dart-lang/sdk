// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'utils.dart';

/// Test that library flags (external, synthetic)
/// are serialized and read correctly.
main() {
  Library lib = new Library(Uri.parse("foo://bar.dart"));
  lib.isSynthetic = false;
  Library lib2 = libRoundTrip(lib);
  if (lib2.isSynthetic != false)
    throw "Serialized and re-read library had change in synthetic flag.";

  lib = new Library(Uri.parse("foo://bar.dart"));
  lib.isSynthetic = true;
  lib2 = libRoundTrip(lib);
  if (lib2.isSynthetic != true)
    throw "Serialized and re-read library had change in synthetic flag.";
}
