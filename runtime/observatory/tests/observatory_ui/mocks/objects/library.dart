// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class LibraryRefMock implements M.LibraryRef {
  final String id;
  final String name;
  final String uri;
  const LibraryRefMock({this.id, this.name, this.uri});
}

class LibraryMock implements M.Library {
  final String id;
  final String name;
  final String uri;
  final bool debuggable;
  final Iterable<M.ScriptRef> scripts;
  final Iterable<M.ClassRef> classes;
  const LibraryMock({this.id, this.name, this.uri, this.debuggable,
      this.scripts: const [], this.classes: const []});
}
