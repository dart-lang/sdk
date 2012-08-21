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

  Generator topLevelGenerator =
      true ? conservativeGenerator : new MinifyingGenerator('ABCD').generate;
  String generateUniqueName(name) {
    String newName = topLevelGenerator(
        name, usedTopLevelIdentifiers.contains);
    usedTopLevelIdentifiers.add(newName);
    return newName;
  }

  String renameElement(Element element) {
    assert(element.isTopLevel());
    // TODO(smok): Make sure that the new name does not conflict with existing
    // local identifiers.
    String originalName = element.name.slowToString();
    LibraryElement library = element.getLibrary();
    if (library === compiler.coreLibrary
        || element == compiler.mainApp.find(Compiler.MAIN)) return originalName;
    if (isDartCoreLib(compiler, library)) {
      final prefix =
          imports.putIfAbsent(library, () => generateUniqueName('p'));
      return '$prefix.$originalName';
    }

    return getName(library, originalName,
                   () => generateUniqueName(originalName));
  }

  renameNodes(Collection<Node> nodes, renamer) {
    for (Node node in nodes) {
      renames[node] = renamer(node);
    }
  }

  renameNodes(placeholderCollector.nullNodes, (_) => '');
  renameNodes(placeholderCollector.unresolvedNodes,
      (_) => generateUniqueName('Unresolved'));
  placeholderCollector.elementNodes.forEach(
      (Element element, Set<Node> nodes) {
        String renamedElement = renameElement(element);
        renameNodes(nodes, (_) => renamedElement);
  });
  placeholderCollector.localPlaceholders.forEach(
      (FunctionElement element, Set<LocalPlaceholder> localPlaceholders) {
        // TODO(smok): Check for conflicts with class fields and take usages
        // into account.
        localPlaceholders.forEach((LocalPlaceholder placeholder) {
          renameNodes(placeholder.nodes, (_) => placeholder.identifier);
        });
      });
  placeholderCollector.privateNodes.forEach(
      (LibraryElement library, Set<Identifier> nodes) {
        renameNodes(nodes, (node) =>
            renamePrivateIdentifier(library, node.source.slowToString()));
  });
}

typedef String Generator(String originalName, bool isForbidden(String name));

/** Always tries to return original identifier name unless it is forbidden. */
String conservativeGenerator(
    String originalName, bool isForbidden(String name)) {
  String newName = originalName;
  while (isForbidden(newName)) {
    newName = 'p_$newName';
  }
  return newName;
}

/** Always tries to generate the most compact identifier. */
class MinifyingGenerator {
  final String alphabet;
  int nextIdIndex;

  MinifyingGenerator(this.alphabet) : nextIdIndex = 0;

  String generate(String originalName, bool isForbidden(String name)) {
    String newName;
    do {
      newName = getNextId();
    } while(isForbidden(newName));
    return newName;
  }

  /**
   * Generates next mini ID with current index and alphabet.
   * Advances current index.
   * In other words, it converts index to visual representation
   * as if digits are given characters.
   */
  String getNextId() {
    // It's like converting index in decimal to [chars] radix.
    int index = nextIdIndex++;
    int length = alphabet.length;
    StringBuffer resultBuilder = new StringBuffer();
    while (index >= length) {
      resultBuilder.add(alphabet[index % length]);
      index ~/= length;
    }
    resultBuilder.add(alphabet[index]);
    return resultBuilder.toString();
  }
}
