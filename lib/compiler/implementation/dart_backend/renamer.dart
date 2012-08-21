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

  Generator topLevelGenerator =
      true ? conservativeGenerator : new MinifyingGenerator('ABCD').generate;
  String generateUniqueName(name) {
    String newName = topLevelGenerator(
        name, usedTopLevelIdentifiers.contains);
    usedTopLevelIdentifiers.add(newName);
    return newName;
  }

  rename(library, originalName) =>
      renamed.putIfAbsent(library, () => <String>{})
          .putIfAbsent(originalName, () => generateUniqueName(originalName));

  String renameElement(Element element) {
    assert(element.isTopLevel() || element is TypeVariableElement);
    // TODO(smok): Make sure that the new name does not conflict with existing
    // local identifiers.
    String originalName = element.name.slowToString();
    LibraryElement library = element.getLibrary();
    if (isDartCoreLib(compiler, library)) {
      final prefix =
          imports.putIfAbsent(library, () => generateUniqueName('p'));
      return '$prefix.$originalName';
    }

    return rename(library, originalName);
  }

  renameNodes(Collection<Node> nodes, renamer) {
    final comparison = compareBy((node) => node.getBeginToken().charOffset);
    for (Node node in sorted(nodes, comparison)) {
      renames[node] = renamer(node);
    }
  }

  sortedForEach(Map<Element, Dynamic> map, f) {
    for (Element element in sortElements(map.getKeys())) {
      f(element, map[element]);
    }
  }

  renameNodes(placeholderCollector.nullNodes, (_) => '');
  renameNodes(placeholderCollector.unresolvedNodes,
      (_) => generateUniqueName('Unresolved'));
  sortedForEach(placeholderCollector.elementNodes, (element, nodes) {
    String renamedElement = renameElement(element);
    renameNodes(nodes, (_) => renamedElement);
  });
  sortedForEach(placeholderCollector.localPlaceholders,
      (element, placeholders) {
    // TODO(smok): Check for conflicts with class fields and take usages
    // into account.
    for (LocalPlaceholder placeholder in placeholders) {
      renameNodes(placeholder.nodes, (_) => placeholder.identifier);
    }
  });
  sortedForEach(placeholderCollector.privateNodes, (library, nodes) {
    renameNodes(nodes, (node) => rename(library, node.source.slowToString()));
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
