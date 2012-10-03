// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Function get _compareNodes =>
    compareBy((n) => n.getBeginToken().charOffset);

typedef String _Renamer(Renamable renamable);
abstract class Renamable {
  const int RENAMABLE_TYPE_ELEMENT = 1;
  const int RENAMABLE_TYPE_MEMBER = 2;
  const int RENAMABLE_TYPE_LOCAL = 3;

  final Set<Node> nodes;
  final _Renamer renamer;

  Renamable(this.nodes, this.renamer);
  int compareTo(Renamable other) {
    int nodesDiff = other.nodes.length.compareTo(this.nodes.length);
    if (nodesDiff != 0) return nodesDiff;
    int typeDiff = this.getTypeId().compareTo(other.getTypeId());
    return typeDiff != 0 ? typeDiff : compareInternals(other);
  }

  abstract int compareInternals(Renamable other);
  abstract int getTypeId();

  String rename() => renamer(this);
}

class ElementRenamable extends Renamable {
  final Element element;

  ElementRenamable(this.element, Set<Node> nodes, _Renamer renamer)
      : super(nodes, renamer);

  int compareInternals(ElementRenamable other) =>
      compareElements(this.element, other.element);
  int getTypeId() => RENAMABLE_TYPE_ELEMENT;
}

class MemberRenamable extends Renamable {
  final String identifier;
  MemberRenamable(this.identifier, Set<Node> nodes, _Renamer renamer)
      : super(nodes, renamer);
  int compareInternals(MemberRenamable other) =>
      this.identifier.compareTo(other.identifier);
  int getTypeId() => RENAMABLE_TYPE_MEMBER;
}

class LocalRenamable extends Renamable {
  LocalRenamable(Set<Node> nodes, _Renamer renamer) : super(nodes, renamer);
  int compareInternals(LocalRenamable other) =>
      _compareNodes(sorted(this.nodes, _compareNodes)[0],
          sorted(other.nodes, _compareNodes)[0]);
  int getTypeId() => RENAMABLE_TYPE_LOCAL;
}

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

  renameNodes(Collection<Node> nodes, renamer) {
    for (Node node in sorted(nodes, _compareNodes)) {
      renames[node] = renamer(node);
    }
  }

  sortedForEach(Map<Element, Dynamic> map, f) {
    for (Element element in sortElements(map.getKeys())) {
      f(element, map[element]);
    }
  }

  Function makeElementRenamer(rename, generateUniqueName) => (element) {
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
  };

  Function makeRenamer(generateUniqueName) =>
      (library, originalName) =>
          renamed.putIfAbsent(library, () => <String>{})
              .putIfAbsent(originalName,
                  () => generateUniqueName(originalName));

  // Renamer function that takes library and original name and returns a new
  // name for given identifier.
  Function rename;
  // A function that takes original identifier name and generates a new unique
  // identifier.
  Function generateUniqueName;
  if (compiler.enableMinification) {
    MinifyingGenerator generator = new MinifyingGenerator();
    Set<String> forbiddenIdentifiers = new Set<String>.from(['main']);
    forbiddenIdentifiers.addAll(Keyword.keywords.getKeys());
    generateUniqueName = (_) =>
        generator.generate(forbiddenIdentifiers.contains);
    rename = makeRenamer(generateUniqueName);
    Function renameElement = makeElementRenamer(rename, generateUniqueName);

    Set<String> allParameterIdentifiers = new Set<String>();
    for (var functionScope in placeholderCollector.functionScopes.getValues()) {
      allParameterIdentifiers.addAll(functionScope.parameterIdentifiers);
    }
    // Build a sorted (by usage) list of local nodes that will be renamed to
    // the same identifier. So the top-used local variables in all functions
    // will be renamed first and will all share the same new identifier.
    List<Set<Node>> allSortedLocals = new List<Set<Node>>();
    for (var functionScope in placeholderCollector.functionScopes.getValues()) {
      // Add current sorted local identifiers to the whole sorted list
      // of all local identifiers for all functions.
      List<LocalPlaceholder> currentSortedPlaceholders =
          sorted(functionScope.localPlaceholders,
              compareBy((LocalPlaceholder ph) => -ph.nodes.length));
      List<Set<Node>> currentSortedNodes =
          currentSortedPlaceholders.map((ph) => ph.nodes);
      // Make room in all sorted locals list for new stuff.
      while (currentSortedNodes.length > allSortedLocals.length) {
        allSortedLocals.add(new Set<Node>());
      }
      for (int i = 0; i < currentSortedNodes.length; i++) {
        allSortedLocals[i].addAll(currentSortedNodes[i]);
      }
    }

    // Rename elements, members and locals together based on their usage count,
    // otherwise when we rename elements first there will be no good identifiers
    // left for members even if they are used often.
    String elementRenamer(ElementRenamable elementRenamable) =>
        renameElement(elementRenamable.element);
    String memberRenamer(MemberRenamable memberRenamable) =>
        generator.generate((name) =>
            forbiddenIdentifiers.contains(name)
            || fixedMemberNames.contains(name));
    String localRenamer(LocalRenamable localRenamable) =>
        generator.generate((name) =>
            allParameterIdentifiers.contains(name)
            || forbiddenIdentifiers.contains(name)
            || fixedMemberNames.contains(name));
    List<Renamable> renamables = [];
    placeholderCollector.elementNodes.forEach(
        (Element element, Set<Node> nodes) {
      renamables.add(new ElementRenamable(element, nodes, elementRenamer));
    });
    placeholderCollector.memberPlaceholders.forEach(
        (String memberName, Set<Identifier> identifiers) {
      renamables.add(
          new MemberRenamable(memberName, identifiers, memberRenamer));
    });
    for (Set<Node> localIdentifiers in allSortedLocals) {
      renamables.add(new LocalRenamable(localIdentifiers, localRenamer));
    }
    renamables.sort((Renamable renamable1, Renamable renamable2) =>
        renamable1.compareTo(renamable2));
    for (Renamable renamable in renamables) {
      String newName = renamable.rename();
      renameNodes(renamable.nodes, (_) => newName);
    }
  } else {
    // TODO(antonm): we should also populate this set with top-level
    // names from core library.
    // Never rename anything to 'main'.
    final usedTopLevelOrMemberIdentifiers = new Set<String>();
    usedTopLevelOrMemberIdentifiers.add('main');
    generateUniqueName = (originalName) {
      String newName = conservativeGenerator(
          originalName, usedTopLevelOrMemberIdentifiers.contains);
      usedTopLevelOrMemberIdentifiers.add(newName);
      return newName;
    };
    rename = makeRenamer(generateUniqueName);
    Function renameElement = makeElementRenamer(rename, generateUniqueName);
    // Rename elements.
    sortedForEach(placeholderCollector.elementNodes,
        (Element element, Set<Node> nodes) {
      renameNodes(nodes, (_) => renameElement(element));
    });

    // Rename locals.
    sortedForEach(placeholderCollector.functionScopes,
        (functionElement, functionScope) {
      Set<LocalPlaceholder> placeholders = functionScope.localPlaceholders;
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
            conservativeGenerator(placeholder.identifier, (name) =>
                functionScope.parameterIdentifiers.contains(name)
                || usedTopLevelOrMemberIdentifiers.contains(name)
                || usedLocalIdentifiers.contains(name)
                || memberIdentifiers.contains(name));
        usedLocalIdentifiers.add(nextId);
        renameNodes(placeholder.nodes, (_) => nextId);
      }
    });

    final usedMemberIdentifiers = new Set<String>.from(fixedMemberNames);
    // Do not rename members to top-levels, that allows to avoid renaming
    // members to constructors.
    usedMemberIdentifiers.addAll(usedTopLevelOrMemberIdentifiers);
    placeholderCollector.memberPlaceholders.forEach((identifier, nodes) {
      String newIdentifier = conservativeGenerator(
          identifier, usedMemberIdentifiers.contains);
      renameNodes(nodes, (_) => newIdentifier);
    });
  }

  sortedForEach(placeholderCollector.privateNodes, (library, nodes) {
    renameNodes(nodes, (node) => rename(library, node.source.slowToString()));
  });
  renameNodes(placeholderCollector.unresolvedNodes,
      (_) => generateUniqueName('Unresolved'));
  renameNodes(placeholderCollector.nullNodes, (_) => '');
  if (cutDeclarationTypes) {
    for (DeclarationTypePlaceholder placeholder in
         placeholderCollector.declarationTypePlaceholders) {
      renames[placeholder.typeNode] = placeholder.requiresVar ? 'var' : '';
    }
  }
}

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
  static const String firstCharAlphabet =
      r'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  static const String otherCharsAlphabet =
      r'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_$';
  int nextIdIndex;

  MinifyingGenerator() : nextIdIndex = 0;

  String generate(bool isForbidden(String name)) {
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
