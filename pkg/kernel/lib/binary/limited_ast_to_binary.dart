// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_to_binary.dart';

/// Writes libraries that satisfy the [predicate].
///
/// Only the referenced subset of canonical names is indexed and written,
/// so we don't waste time indexing all libraries of a component, when only
/// a tiny subset is used.
class LimitedBinaryPrinter extends BinaryPrinter {
  final LibraryFilter predicate;

  LimitedBinaryPrinter(
      Sink<List<int>> sink, this.predicate, bool excludeUriToSource,
      {bool includeOffsets = true})
      : super(sink,
            includeSources: !excludeUriToSource,
            includeOffsets: includeOffsets);

  @override
  void computeCanonicalNames(Component component) {
    for (var library in component.libraries) {
      if (predicate(library)) {
        component.root
            .getChildFromUri(library.importUri)
            .bindTo(library.reference);
        library.computeCanonicalNames();
      }
    }
  }

  @override
  bool shouldWriteLibraryCanonicalNames(Library library) {
    return predicate(library);
  }

  void writeLibraries(Component component) {
    for (int i = 0; i < component.libraries.length; ++i) {
      Library library = component.libraries[i];
      if (predicate(library)) writeLibraryNode(library);
    }
  }

  @override
  void writeNode(Node node) {
    if (node is Library) {
      throw "Internal error: writeNode should not see a Library.";
    }
    super.writeNode(node);
  }

  @override
  void writeComponentIndex(Component component, List<Library> libraries) {
    var librariesToWrite = libraries.where(predicate).toList();
    super.writeComponentIndex(component, librariesToWrite);
  }
}
