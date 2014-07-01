// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_backend;

Comparator get _compareNodes =>
    compareBy((n) => n.getBeginToken().charOffset);

typedef String _Renamer(Renamable renamable);

abstract class Renamable {
  final int RENAMABLE_TYPE_ELEMENT = 1;
  final int RENAMABLE_TYPE_MEMBER = 2;
  final int RENAMABLE_TYPE_LOCAL = 3;

  final Set<Node> nodes;
  final _Renamer renamer;

  Renamable(this.nodes, this.renamer);
  int compareTo(Renamable other) {
    int nodesDiff = other.nodes.length.compareTo(this.nodes.length);
    if (nodesDiff != 0) return nodesDiff;
    int typeDiff = this.getTypeId().compareTo(other.getTypeId());
    return typeDiff != 0 ? typeDiff : compareInternals(other);
  }

  int compareInternals(Renamable other);
  int getTypeId();

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
    Map<Element, LibraryElement> reexportingLibraries,
    bool cutDeclarationTypes,
    {bool uniqueGlobalNaming: false}) {
  final Map<LibraryElement, Map<String, String>> renamed
      = new Map<LibraryElement, Map<String, String>>();

  renameNodes(Iterable<Node> nodes, renamer) {
    for (Node node in sorted(nodes, _compareNodes)) {
      renames[node] = renamer(node);
    }
  }

  sortedForEach(Map<Element, dynamic> map, f) {
    for (Element element in sortElements(map.keys)) {
      f(element, map[element]);
    }
  }

  String renameType(DartType type, Function renameElement) {
    if (type.isDynamic) return 'dynamic';
    // TODO(smok): Do not rename type if it is in platform library or
    // js-helpers.
    StringBuffer result = new StringBuffer(renameElement(type.element));
    if (type is GenericType && !type.treatAsRaw) {
      result.write('<');
      List<DartType> arguments = type.typeArguments;
      result.write(renameType(arguments.first, renameElement));
      for (int index = 1; index < arguments.length; index++) {
        result.write(',');
        result.write(renameType(arguments[index], renameElement));
      }
      result.write('>');
    }
    return result.toString();
  }

  String renameConstructor(Element element, ConstructorPlaceholder placeholder,
      Function renameString, Function renameElement) {
    assert(element.isConstructor);
    StringBuffer result = new StringBuffer();
    String name = element.name;
    if (element.name != '') {
      // Named constructor or factory. Is there a more reliable way to check
      // this case?
      if (!placeholder.isRedirectingCall) {
        result.write(renameType(placeholder.type, renameElement));
        result.write('.');
      }
      if (!element.library.isPlatformLibrary) {
        name = renameString(element.library, name);
      }
      result.write(name);
    } else {
      assert(!placeholder.isRedirectingCall);
      result.write(renameType(placeholder.type, renameElement));
    }
    return result.toString();
  }

  Function makeElementRenamer(rename, generateUniqueName) => (element) {
    assert(Elements.isErroneousElement(element) ||
           Elements.isStaticOrTopLevel(element) ||
           element is TypeVariableElement);
    // TODO(smok): We may want to reuse class static field and method names.
    String originalName = element.name;
    LibraryElement library = element.library;
    if (identical(element.library, compiler.coreLibrary)) {
      return originalName;
    }
    if (library.isPlatformLibrary) {
      assert(element.isTopLevel);
      if (reexportingLibraries.containsKey(element)) {
        library = reexportingLibraries[element];
      }
      if (!library.isInternalLibrary) {
        final prefix =
            imports.putIfAbsent(library, () => generateUniqueName('p'));
        return '$prefix.$originalName';
      }
    }

    return rename(library, originalName);
  };

  Function makeRenamer(generateUniqueName) =>
      (library, originalName) =>
          renamed.putIfAbsent(library, () => {})
              .putIfAbsent(originalName,
                  () => generateUniqueName(originalName));

  // Renamer function that takes library and original name and returns a new
  // name for given identifier.
  Function rename;
  Function renameElement;
  // A function that takes original identifier name and generates a new unique
  // identifier.
  Function generateUniqueName;

  Set<String> allNamedParameterIdentifiers = new Set<String>();
  for (var functionScope in placeholderCollector.functionScopes.values) {
    allNamedParameterIdentifiers.addAll(functionScope.parameterIdentifiers);
  }

  if (compiler.enableMinification) {
    MinifyingGenerator generator = new MinifyingGenerator();
    Set<String> forbiddenIdentifiers = new Set<String>.from(['main']);
    forbiddenIdentifiers.addAll(Keyword.keywords.keys);
    forbiddenIdentifiers.addAll(fixedMemberNames);
    generateUniqueName = (_) =>
        generator.generate((name) =>
            forbiddenIdentifiers.contains(name)
            || allNamedParameterIdentifiers.contains(name));
    rename = makeRenamer(generateUniqueName);
    renameElement = makeElementRenamer(rename, generateUniqueName);

    List<Set<Node>> allLocals = new List<Set<Node>>();

    // Build a list sorted by usage of local nodes that will be renamed to
    // the same identifier. So the top-used local variables in all functions
    // will be renamed first and will all share the same new identifier.
    for (var functionScope in placeholderCollector.functionScopes.values) {
      // Add current sorted local identifiers to the whole sorted list
      // of all local identifiers for all functions.
      List<LocalPlaceholder> currentSortedPlaceholders =
          sorted(functionScope.localPlaceholders,
              compareBy((LocalPlaceholder ph) => -ph.nodes.length));
      List<Set<Node>> currentSortedNodes =
          currentSortedPlaceholders.map((ph) => ph.nodes).toList();
      // Make room in all sorted locals list for new stuff.
      while (currentSortedNodes.length > allLocals.length) {
        allLocals.add(new Set<Node>());
      }
      for (int i = 0; i < currentSortedNodes.length; i++) {
        allLocals[i].addAll(currentSortedNodes[i]);
      }
    }

    // Rename elements, members and locals together based on their usage count,
    // otherwise when we rename elements first there will be no good identifiers
    // left for members even if they are used often.
    String elementRenamer(ElementRenamable elementRenamable) =>
        renameElement(elementRenamable.element);
    String memberRenamer(MemberRenamable memberRenamable) =>
        generator.generate(forbiddenIdentifiers.contains);
    Function localRenamer = generateUniqueName;
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
    for (Set<Node> localIdentifiers in allLocals) {
      renamables.add(new LocalRenamable(localIdentifiers, localRenamer));
    }
    renamables.sort((Renamable renamable1, Renamable renamable2) =>
        renamable1.compareTo(renamable2));
    for (Renamable renamable in renamables) {
      String newName = renamable.rename();
      renameNodes(renamable.nodes, (_) => newName);
    }
  } else {
    // Never rename anything to 'main'.
    final usedTopLevelOrMemberIdentifiers = new Set<String>();
    usedTopLevelOrMemberIdentifiers.add('main');
    usedTopLevelOrMemberIdentifiers.addAll(fixedMemberNames);
    generateUniqueName = (originalName) {
      String newName = conservativeGenerator(
          originalName, (name) =>
              usedTopLevelOrMemberIdentifiers.contains(name)
              || allNamedParameterIdentifiers.contains(name));
      usedTopLevelOrMemberIdentifiers.add(newName);
      return newName;
    };
    rename = makeRenamer(generateUniqueName);
    renameElement = makeElementRenamer(rename, generateUniqueName);
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
      if (functionElement.enclosingClass != null) {
        functionElement.enclosingClass.forEachMember(
            (enclosingClass, member) {
              memberIdentifiers.add(member.name);
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

  // Rename constructors.
  sortedForEach(placeholderCollector.constructorPlaceholders,
      (Element constructor, List<ConstructorPlaceholder> placeholders) {
        for (ConstructorPlaceholder ph in placeholders) {
          renames[ph.node] =
              renameConstructor(constructor, ph, rename, renameElement);
        }
  });
  sortedForEach(placeholderCollector.privateNodes, (library, nodes) {
    renameNodes(nodes, (node) => rename(library, node.source));
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

/**
 * Generates mini ID based on index.
 * In other words, it converts index to visual representation
 * as if digits are given characters.
 */
String generateMiniId(int index) {
  const String firstCharAlphabet =
      r'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  const String otherCharsAlphabet =
      r'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_$';
  // It's like converting index in decimal to [chars] radix.
  if (index < firstCharAlphabet.length) return firstCharAlphabet[index];
  StringBuffer resultBuilder = new StringBuffer();
  resultBuilder.writeCharCode(
     firstCharAlphabet.codeUnitAt(index % firstCharAlphabet.length));
  index ~/= firstCharAlphabet.length;
  int length = otherCharsAlphabet.length;
  while (index >= length) {
    resultBuilder.writeCharCode(otherCharsAlphabet.codeUnitAt(index % length));
    index ~/= length;
  }
  resultBuilder.write(otherCharsAlphabet[index]);
  return resultBuilder.toString();
}


/** Always tries to return original identifier name unless it is forbidden. */
String conservativeGenerator(String name, bool isForbidden(String name)) {
  String result = name;
  int index = 0;
  while (isForbidden(result)) {
    result = '${generateMiniId(index++)}_$name';
  }
  return result;
}


/** Always tries to generate the most compact identifier. */
class MinifyingGenerator {
  int index = 0;

  MinifyingGenerator();

  String generate(bool isForbidden(String name)) {
    String result;
    do {
      result = generateMiniId(index++);
    } while (isForbidden(result));
    return result;
  }
}