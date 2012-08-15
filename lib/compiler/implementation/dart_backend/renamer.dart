// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Renames only top-level elements that would let to ambiguity if not renamed.
 * TODO(smok): Make sure that top-level fields are correctly renamed.
 */
void renamePlaceholders(
    Compiler compiler,
    PlaceholderCollector placeholderCollector,
    Map<Node, String> renames,
    Map<LibraryElement, String> imports) {
  final Map<LibraryElement, Map<String, String>> renamed
      = new Map<LibraryElement, Map<String, String>>();
  final Set<String> usedTopLevelIdentifiers = new Set<String>();
  int privateNameCounter = 0;

  String getName(LibraryElement library, String originalName, renamer) =>
      renamed.putIfAbsent(library, () => <String>{})
          .putIfAbsent(originalName, renamer);

  String renamePrivateIdentifier(LibraryElement library, String id) =>
      getName(library, id, () => '_${privateNameCounter++}${id}');

  String generateUniqueName(name) {
    while (usedTopLevelIdentifiers.contains(name)) name = 'p_$name';
    usedTopLevelIdentifiers.add(name);
    return name;
  }

  String renameElement(Element element) {
    assert(element.isTopLevel());
    // TODO(smok): Make sure that the new name does not conflict with existing
    // local identifiers.
    String originalName = element.name.slowToString();
    LibraryElement library = element.getLibrary();
    if (library === compiler.coreLibrary) return originalName;
    if (isDartCoreLib(compiler, library)) {
      final prefix =
          imports.putIfAbsent(library, () => generateUniqueName('p'));
      return '$prefix.$originalName';
    }

    return getName(library, originalName,
                   () => generateUniqueName(originalName));
  }

  // Rename main() right now so that nobody takes its place.
  renameElement(compiler.mainApp.find(Compiler.MAIN));

  placeholderCollector.nullNodes.forEach((Node node) {
    renames[node] = '';
  });
  placeholderCollector.unresolvedNodes.forEach((Node node) {
    renames[node] = generateUniqueName('Unresolved');
  });
  placeholderCollector.elementNodes.forEach(
      (Element element, Set<Node> nodes) {
        String renamedElement = renameElement(element);
        nodes.forEach((Node node) {
          renames[node] = renamedElement;
        });
  });
  placeholderCollector.localPlaceholders.forEach(
      (FunctionElement element, Set<LocalPlaceholder> localPlaceholders) {
        // TODO(smok): Check for conflicts with class fields and take usages
        // into account.
        localPlaceholders.forEach((LocalPlaceholder placeholder) {
          placeholder.nodes.forEach((Node node) {
            renames[node] = placeholder.identifier;
          });
        });
      });
  placeholderCollector.privateNodes.forEach(
      (LibraryElement library, Set<Identifier> nodes) {
        nodes.forEach((Identifier node) {
          renames[node] =
              renamePrivateIdentifier(library, node.source.slowToString());
        });
  });
}
