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
    Map<LibraryElement, String> imports,
    Set<String> fixedMemberNames,
    bool minify,
    bool cutDeclarationTypes) {
  final Map<LibraryElement, Map<String, String>> renamed
      = new Map<LibraryElement, Map<String, String>>();
  Generator topLevelGenerator =
      minify ? new MinifyingGenerator('ABCDEFGHIJKLMNOPQRSTUVWXYZ').generate
          : conservativeGenerator;
  makeGenerator(usedIdentifierSet) => (name) {
    String newName = topLevelGenerator(name, usedIdentifierSet.contains);
    usedIdentifierSet.add(newName);
    return newName;
  };

  final usedTopLevelIdentifiers = new Set<String>();
  // TODO(antonm): we should also populate this set with top-level
  // names from core library.
  usedTopLevelIdentifiers.add('main'); // Never rename anything to 'main'.
  final generateUniqueName = makeGenerator(usedTopLevelIdentifiers);

  rename(library, originalName) =>
      renamed.putIfAbsent(library, () => <String>{})
          .putIfAbsent(originalName, () => generateUniqueName(originalName));

  String renameElement(Element element) {
    assert(Elements.isStaticOrTopLevel(element)
           || element is TypeVariableElement);
    // TODO(smok): Make sure that the new name does not conflict with existing
    // local identifiers.
    // TODO(smok): We may want to reuse class static field and method names.
    String originalName = element.name.slowToString();
    LibraryElement library = element.getLibrary();
    if (library.isPlatformLibrary) {
      assert(element.isTopLevel());
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
  sortedForEach(placeholderCollector.functionScopes,
      (functionElement, functionScope) {
    Set<LocalPlaceholder> placeholders = functionScope.localPlaceholders;
    Generator localGenerator =
        minify ? new MinifyingGenerator('abcdefghijklmnopqrstuvwxyz').generate
            : conservativeGenerator;
    Set<String> memberIdentifiers = new Set<String>();
    if (functionElement.getEnclosingClass() !== null) {
      functionElement.getEnclosingClass().forEachMember(
          (enclosingClass, member) {
        memberIdentifiers.add(member.name.slowToString());
      });
    }
    Set<String> usedLocalIdentifiers = new Set<String>();
    // TODO(smok): Take usages into account.
    for (LocalPlaceholder placeholder in placeholders) {
      String nextId =
          localGenerator(placeholder.identifier, (name) =>
              functionScope.parameterIdentifiers.contains(name)
                  || usedTopLevelIdentifiers.contains(name)
                  || usedLocalIdentifiers.contains(name)
                  || memberIdentifiers.contains(name));
      usedLocalIdentifiers.add(nextId);
      renameNodes(placeholder.nodes, (_) => nextId);
    }
  });
  sortedForEach(placeholderCollector.privateNodes, (library, nodes) {
    renameNodes(nodes, (node) => rename(library, node.source.slowToString()));
  });
  if (cutDeclarationTypes) {
    for (DeclarationTypePlaceholder placeholder in
         placeholderCollector.declarationTypePlaceholders) {
      renames[placeholder.typeNode] = placeholder.requiresVar ? 'var' : '';
    }
  }

  final usedMemberIdentifiers = new Set<String>.from(fixedMemberNames);
  // Do not rename members to top-levels, that allows to avoid renaming
  // members to constructors.
  usedMemberIdentifiers.addAll(usedTopLevelIdentifiers);
  final generateMemberIdentifier = makeGenerator(usedMemberIdentifiers);
  placeholderCollector.memberPlaceholders.forEach((identifier, nodes) {
    final newIdentifier = generateMemberIdentifier(identifier);
    renameNodes(nodes, (_) => newIdentifier);
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
