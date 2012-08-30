// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Renames only top-level elements that would let to ambiguity if not renamed.
 */
void renamePlaceholders(
    Compiler compiler,
    PlaceholderCollector placeholderCollector,
    Map<Node, String> renames,
    Map<LibraryElement, String> imports,
    Set<String> fixedMemberNames,
    bool cutDeclarationTypes) {
  final Map<LibraryElement, Map<String, String>> renamed
      = new Map<LibraryElement, Map<String, String>>();
  Generator topLevelGenerator = compiler.enableMinification
      ? new MinifyingGenerator('ABCDEFGHIJKLMNOPQRSTUVWXYZ').generate
      : conservativeGenerator;
  makeGenerator(usedIdentifierSet) => (name) {
    String newName = topLevelGenerator(name, usedIdentifierSet.contains);
    usedIdentifierSet.add(newName);
    return newName;
  };

  final usedTopLevelOrMemberIdentifiers = new Set<String>();
  // TODO(antonm): we should also populate this set with top-level
  // names from core library.
  // Never rename anything to 'main'.
  usedTopLevelOrMemberIdentifiers.add('main');
  final generateUniqueName = makeGenerator(usedTopLevelOrMemberIdentifiers);

  rename(library, originalName) =>
      renamed.putIfAbsent(library, () => <String>{})
          .putIfAbsent(originalName, () => generateUniqueName(originalName));

  String renameElement(Element element) {
    assert(Elements.isStaticOrTopLevel(element)
           || element is TypeVariableElement);
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

  // Rename top-level elements and members together, otherwise when we rename
  // elements there is no good identifiers left for members even if they are
  // used often.
  List<Dynamic> elementsAndMembers = [];
  elementsAndMembers.addAll(placeholderCollector.elementNodes.getKeys());
  elementsAndMembers.addAll(placeholderCollector.memberPlaceholders.getKeys());
  getElementOrMemberUsages(item) =>
      item is Element ? placeholderCollector.elementNodes[item].length
          : placeholderCollector.memberPlaceholders[item].length;
  compareElementOrMemberUsages(item1, item2) {
    int usagesDiff =
        getElementOrMemberUsages(item2) - getElementOrMemberUsages(item1);
    if (usagesDiff != 0) return usagesDiff;
    if (item1 is Element && item2 is String) return -1;
    if (item1 is String && item2 is Element) return 1;
    if (item1 is Element && item2 is Element) {
      return compareElements(item1, item2);
    } else if (item1 is String && item2 is String) {
      return item1.compareTo(item2);
    } else {
      throw 'Unreachable';
    }
  }
  elementsAndMembers.sort(compareElementOrMemberUsages);
  for (var item in elementsAndMembers) {
    String newName;
    Set<Node> nodes;
    if (item is Element) {
      newName = renameElement(item);
      nodes = placeholderCollector.elementNodes[item];
    } else {
      assert(item is String);
      newName = topLevelGenerator(item, (name) =>
          usedTopLevelOrMemberIdentifiers.contains(name)
              || fixedMemberNames.contains(name));
      nodes = placeholderCollector.memberPlaceholders[item];
    }
    renameNodes(nodes, (_) => newName);
  }

  renameNodes(placeholderCollector.nullNodes, (_) => '');
  renameNodes(placeholderCollector.unresolvedNodes,
      (_) => generateUniqueName('Unresolved'));

  sortedForEach(placeholderCollector.functionScopes,
      (functionElement, functionScope) {
    Set<LocalPlaceholder> placeholders = functionScope.localPlaceholders;
    Generator localGenerator = compiler.enableMinification
        ? new MinifyingGenerator('abcdefghijklmnopqrstuvwxyz').generate
        : conservativeGenerator;
    Set<String> memberIdentifiers = new Set<String>();
    if (functionElement.getEnclosingClass() !== null) {
      functionElement.getEnclosingClass().forEachMember(
          (enclosingClass, member) {
        memberIdentifiers.add(member.name.slowToString());
      });
    }
    Set<String> usedLocalIdentifiers = new Set<String>();
    for (LocalPlaceholder placeholder in placeholders) {
      String nextId =
          localGenerator(placeholder.identifier, (name) =>
              functionScope.parameterIdentifiers.contains(name)
                  || usedTopLevelOrMemberIdentifiers.contains(name)
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
  static const String otherCharsAlphabet =
      @'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_$';
  final String firstCharAlphabet;
  int nextIdIndex;

  MinifyingGenerator(this.firstCharAlphabet) : nextIdIndex = 0;

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
    StringBuffer resultBuilder = new StringBuffer();
    if (index < firstCharAlphabet.length) return firstCharAlphabet[index];
    resultBuilder.add(firstCharAlphabet[index % firstCharAlphabet.length]);
    index ~/= firstCharAlphabet.length;
    int length = otherCharsAlphabet.length;
    while (index >= length) {
      resultBuilder.add(otherCharsAlphabet[index % length]);
      index ~/= length;
    }
    resultBuilder.add(otherCharsAlphabet[index]);
    return resultBuilder.toString();
  }
}
