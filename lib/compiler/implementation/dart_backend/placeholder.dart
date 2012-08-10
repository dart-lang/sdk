// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Placeholder {
  const Placeholder();
  abstract String rename(ConflictingRenamer renamer);
}

class NullPlaceholder extends Placeholder {
  String rename(ConflictingRenamer renamer) => '';
  String toString() => 'null_placeholder[]';
}

class PrivatePlaceholder extends Placeholder {
  final LibraryElement library;
  final Identifier node;
  PrivatePlaceholder(this.library, this.node);
  String rename(ConflictingRenamer renamer) =>
      renamer.renamePrivateIdentifier(library, node.source.slowToString());
  String toString() => 'private_placeholder[node($node), $library]';
}

class ElementPlaceholder extends Placeholder {
  final Element element;
  ElementPlaceholder(this.element);
  String rename(ConflictingRenamer renamer) => renamer.renameElement(element);
  String toString() => 'element_placeholder[$element]';
}

class UnresolvedPlaceholder extends Placeholder {
  const UnresolvedPlaceholder();
  String rename(ConflictingRenamer renamer) =>
      renamer.generateUniqueName('unresolved');
  String toString() => 'unresolved_placeholder';
}
