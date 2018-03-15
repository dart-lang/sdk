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

  /// Excludes all uriToSource information.
  ///
  /// By default the [predicate] above will only exclude canonical names and
  /// kernel libraries, but it will still emit the sources for all libraries.
  /// filtered by libraries matching [predicate].
  // TODO(sigmund): provide a way to filter sources directly based on
  // [predicate]. That requires special logic to handle sources from part files.
  final bool excludeUriToSource;

  LimitedBinaryPrinter(
      Sink<List<int>> sink, this.predicate, this.excludeUriToSource)
      : super(sink);

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

  @override
  void writeLibraries(Component component) {
    var librariesToWrite = component.libraries.where(predicate).toList();
    writeList(librariesToWrite, writeNode);
  }

  @override
  void writeNode(Node node) {
    if (node is Library && !predicate(node)) return;
    super.writeNode(node);
  }

  @override
  void writeComponentIndex(Component component, List<Library> libraries) {
    var librariesToWrite = libraries.where(predicate).toList();
    super.writeComponentIndex(component, librariesToWrite);
  }

  @override
  void indexUris(Component component) {
    if (!excludeUriToSource) {
      super.indexUris(component);
    } else {
      // We pretend not to know any uris, thereby excluding all sources.
    }
  }
}
