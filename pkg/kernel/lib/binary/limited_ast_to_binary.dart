// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_to_binary.dart';

/// Writes libraries that satisfy the [predicate].
///
/// Only the referenced subset of canonical names is indexed and written,
/// so we don't waste time indexing all libraries of a program, when only
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
      : super(sink, stringIndexer: new ReferencesStringIndexer());

  @override
  void addCanonicalNamesForLinkTable(List<CanonicalName> list) {
    ReferencesStringIndexer stringIndexer = this.stringIndexer;
    stringIndexer.referencedNames.forEach((name) {
      if (name.index != -1) return;
      name.index = list.length;
      list.add(name);
    });
  }

  @override
  void buildStringIndex(Program program) {
    program.libraries.where(predicate).forEach((library) {
      stringIndexer.scanLibrary(library);
    });
    stringIndexer.finish();
  }

  @override
  void computeCanonicalNames(Program program) {
    for (var library in program.libraries) {
      if (predicate(library)) {
        program.root
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
  void writeLibraries(Program program) {
    var librariesToWrite = program.libraries.where(predicate).toList();
    writeList(librariesToWrite, writeNode);
  }

  @override
  void writeNode(Node node) {
    if (node is Library && !predicate(node)) return;
    node.accept(this);
  }

  @override
  void writeProgramIndex(Program program, List<Library> libraries) {
    var librariesToWrite = libraries.where(predicate).toList();
    super.writeProgramIndex(program, librariesToWrite);
  }

  void writeUriToSource(Program program) {
    if (!excludeUriToSource) {
      super.writeUriToSource(program);
    } else {
      // Emit a practically empty uriToSrouce table.
      writeStringTable(new StringIndexer());

      // Add an entry for '', which is always included by default.
      writeUtf8Bytes(const <int>[]);
      writeUInt30(0);
    }
  }
}

/// Extension of [StringIndexer] that also indexes canonical names of
/// referenced classes and members.
class ReferencesStringIndexer extends StringIndexer {
  final List<CanonicalName> referencedNames = <CanonicalName>[];

  @override
  defaultMemberReference(Member node) {
    _handleReferencedName(node.canonicalName);
  }

  @override
  visitClassReference(Class node) {
    _handleReferencedName(node.canonicalName);
  }

  @override
  visitLibraryDependency(LibraryDependency node) {
    _handleReferencedName(node.importedLibraryReference.canonicalName);
    super.visitLibraryDependency(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    _handleReferencedName(node.interfaceTargetReference?.canonicalName);
    return super.visitMethodInvocation(node);
  }

  @override
  visitPropertyGet(PropertyGet node) {
    _handleReferencedName(node.interfaceTargetReference?.canonicalName);
    return super.visitPropertyGet(node);
  }

  @override
  visitPropertySet(PropertySet node) {
    _handleReferencedName(node.interfaceTargetReference?.canonicalName);
    return super.visitPropertySet(node);
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    _handleReferencedName(node.interfaceTargetReference?.canonicalName);
    return super.visitSuperMethodInvocation(node);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    _handleReferencedName(node.interfaceTargetReference?.canonicalName);
    return super.visitSuperPropertyGet(node);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    _handleReferencedName(node.interfaceTargetReference?.canonicalName);
    return super.visitSuperPropertySet(node);
  }

  void _handleReferencedName(CanonicalName name) {
    if (name == null || name.parent == null) return;
    _handleReferencedName(name.parent);
    referencedNames.add(name);
    name.index = -1;
    put(name.name);
  }
}
