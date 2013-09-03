// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.libraries_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

main() {
  MirrorSystem mirrors = currentMirrorSystem();
  Expect.isNotNull(mirrors, 'mirrors is null');

  Map<Uri, LibraryMirror> libraries = mirrors.libraries;
  Expect.isNotNull(libraries, 'libraries is null');

  LibraryMirror mirrorsLibrary = libraries[Uri.parse('dart:mirrors')];
  Expect.isNotNull(mirrorsLibrary, 'mirrorsLibrary is null');

  ClassMirror cls = mirrorsLibrary.classes[const Symbol('LibraryMirror')];
  Expect.isNotNull(cls, 'cls is null');

  Expect.equals(const Symbol('dart.mirrors.LibraryMirror'), cls.qualifiedName);
  Expect.equals(reflectClass(LibraryMirror), cls);
}
