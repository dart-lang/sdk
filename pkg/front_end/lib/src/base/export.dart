// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.export;

import 'package:kernel/ast.dart';

import '../builder/builder.dart';
import '../builder/library_builder.dart';
import 'combinator.dart' show CombinatorBuilder;
import 'uri_offset.dart';

class Export {
  /// The compilation unit that is exporting [exported];
  final CompilationUnit exporter;

  /// The library being exported.
  CompilationUnit exportedCompilationUnit;

  final List<CombinatorBuilder>? combinators;

  final int charOffset;

  Export(this.exporter, this.exportedCompilationUnit, this.combinators,
      this.charOffset);

  LibraryBuilder get exportedLibraryBuilder =>
      exportedCompilationUnit.libraryBuilder;

  /// The [LibraryDependency] node corresponding to this import.
  ///
  /// This set in [SourceLibraryBuilder._addDependencies].
  late final LibraryDependency libraryDependency;

  bool addToExportScope(String name, Builder member) {
    if (combinators != null) {
      for (CombinatorBuilder combinator in combinators!) {
        if (combinator.isShow && !combinator.names.contains(name)) return false;
        if (combinator.isHide &&
            // Coverage-ignore(suite): Not run.
            combinator.names.contains(name)) return false;
      }
    }
    return exporter.libraryBuilder.addToExportScope(name, member,
        uriOffset: new UriOffset(exporter.fileUri, charOffset));
  }
}
