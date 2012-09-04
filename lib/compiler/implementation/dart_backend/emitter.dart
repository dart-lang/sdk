// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String emitCode(
      Unparser unparser,
      Map<LibraryElement, String> imports,
      Collection<Node> topLevelNodes,
      Map<ClassNode, Collection<Node>> classMembers) {
  imports.forEach((libraryElement, prefix) {
    unparser.unparseImportTag('${libraryElement.uri}', prefix);
  });

  for (final node in topLevelNodes) {
    if (node is ClassNode) {
      unparser.unparseClassWithBody(node, () {
        // TODO(smok): Filter out default constructors here.
        classMembers[node].forEach(unparser.unparse);
      });
    } else {
      unparser.unparse(node);
    }
  }
}
