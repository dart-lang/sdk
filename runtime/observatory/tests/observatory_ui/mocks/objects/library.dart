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
  final String vmName;
  final M.ClassRef clazz;
  final int size;
  final String uri;
  final bool debuggable;
  final Iterable<M.LibraryDependency> dependencies;
  final Iterable<M.ScriptRef> scripts;
  final Iterable<M.ClassRef> classes;  final Iterable<M.FieldRef> variables;
  final Iterable<M.FunctionRef> functions;
  final M.ScriptRef rootScript;

  const LibraryMock({this.id: 'library-id', this.name: 'library-name',
                     this.vmName: 'library-vmName', this.clazz, this.size,
                     this.uri, this.debuggable, this.dependencies: const [],
                     this.scripts: const [], this.classes: const [],
                     this.variables: const [], this.functions: const [],
                     this.rootScript: const ScriptRefMock()});
}
