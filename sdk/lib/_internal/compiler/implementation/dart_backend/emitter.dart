// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_backend;

void emitCode(
      Unparser unparser,
      Map<LibraryElement, String> imports,
      Iterable<Node> topLevelNodes,
      Map<ClassNode, Iterable<Node>> classMembers) {
  imports.forEach((libraryElement, prefix) {
    unparser.unparseImportTag('${libraryElement.canonicalUri}', prefix);
  });

  for (final node in topLevelNodes) {
    if (node is ClassNode) {
      // TODO(smok): Filter out default constructors here.
      unparser.unparseClassWithBody(node, classMembers[node]);
    } else {
      unparser.unparse(node);
    }
    unparser.newline();
  }
}
