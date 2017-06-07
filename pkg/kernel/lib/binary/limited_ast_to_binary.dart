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

  LimitedBinaryPrinter(Sink<List<int>> sink, this.predicate)
      : super(sink, stringIndexer: new ReferencesStringIndexer());

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
