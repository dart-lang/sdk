// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_prefix_builder;

import 'package:kernel/ast.dart' show LibraryDependency;

import '../builder/builder.dart' show LibraryBuilder, PrefixBuilder;

import 'load_library_builder.dart' show LoadLibraryBuilder;

class KernelPrefixBuilder extends PrefixBuilder {
  final LibraryDependency dependency;

  LoadLibraryBuilder loadLibraryBuilder;

  KernelPrefixBuilder(String name, bool deferred, LibraryBuilder parent,
      this.dependency, int charOffset)
      : super(name, deferred, parent, charOffset) {
    if (deferred) {
      loadLibraryBuilder =
          new LoadLibraryBuilder(parent, dependency, charOffset);
      addToExportScope('loadLibrary', loadLibraryBuilder, charOffset);
    }
  }
}
