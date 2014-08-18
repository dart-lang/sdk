// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_backend;

Comparator get _compareNodes =>
    compareBy((n) => n.getBeginToken().charOffset);

abstract class Renamable implements Comparable {
  final int RENAMABLE_TYPE_ELEMENT = 1;
  final int RENAMABLE_TYPE_MEMBER = 2;
  final int RENAMABLE_TYPE_LOCAL = 3;

  final Set<Node> nodes;

  Renamable(this.nodes);
  int compareTo(Renamable other) {
    int nodesDiff = other.nodes.length.compareTo(this.nodes.length);
    if (nodesDiff != 0) return nodesDiff;
    int typeDiff = this.kind.compareTo(other.kind);
    return typeDiff != 0 ? typeDiff : compareInternals(other);
  }

  int compareInternals(Renamable other);
  int get kind;

  String createNewName(PlaceholderRenamer placeholderRenamer);
}

class GlobalRenamable extends Renamable {
  final Entity entity;

  GlobalRenamable(this.entity, Set<Node> nodes)
      : super(nodes);

  int compareInternals(GlobalRenamable other) =>
      compareElements(this.entity, other.entity);
  int get kind => RENAMABLE_TYPE_ELEMENT;
  String createNewName(PlaceholderRenamer placeholderRenamer) {
    return placeholderRenamer._renameGlobal(entity);
  }
}

class MemberRenamable extends Renamable {
  final String identifier;
  MemberRenamable(this.identifier, Set<Node> nodes)
      : super(nodes);
  int compareInternals(MemberRenamable other) =>
      this.identifier.compareTo(other.identifier);
  int get kind => RENAMABLE_TYPE_MEMBER;
  String createNewName(PlaceholderRenamer placeholderRenamer) {
    return placeholderRenamer._generateMemberName(identifier);
  }
}

class LocalRenamable extends Renamable {
  LocalRenamable(Set<Node> nodes)
      : super(nodes);
  int compareInternals(LocalRenamable other) =>
      _compareNodes(sorted(this.nodes, _compareNodes)[0],
          sorted(other.nodes, _compareNodes)[0]);
  int get kind => RENAMABLE_TYPE_LOCAL;
  String createNewName(PlaceholderRenamer placeholderRenamer) {
    return placeholderRenamer._generateUniqueTopLevelName("");
  }
}

/**
 * Renames only top-level elements that would lead to ambiguity if not renamed.
 */
class PlaceholderRenamer {
  /// After running [computeRenames] this will contain the computed renames.
  final Map<Node, String> renames = new Map<Node, String>();
  /// After running [computeRenames] this will contain the used platform
  /// libraries.
  final Set<LibraryElement> platformImports = new Set<LibraryElement>();

  final Compiler _compiler;
  final Set<String> fixedMemberNames;
  final Map<Element, LibraryElement> reexportingLibraries;
  final bool cutDeclarationTypes;

  final Map<Entity, String> _renamedCache = new Map<Entity, String>();
  final Map<Entity, Map<String, String>> _privateCache =
      new Map<Entity, Map<String, String>>();

  // Identifiers that has already been used, or are reserved by the
  // language/platform.
  Set<String> _forbiddenIdentifiers;
  Set<String> _allNamedParameterIdentifiers;

  Generator _generator;

  PlaceholderRenamer(this._compiler, this.fixedMemberNames,
      this.reexportingLibraries, {this.cutDeclarationTypes}) ;

  void _renameNodes(Iterable<Node> nodes, String renamer(Node node)) {
    for (Node node in sorted(nodes, _compareNodes)) {
      renames[node] = renamer(node);
    }
  }

  String _generateUniqueTopLevelName(originalName) {
    String newName = _generator.generate(originalName, (name) {
      return _forbiddenIdentifiers.contains(name) ||
             _allNamedParameterIdentifiers.contains(name);
    });
    _forbiddenIdentifiers.add(newName);
    return newName;
  }

  String _generateMemberName(String original) {
    return _generator.generate(original, _forbiddenIdentifiers.contains);
  }

  /// Looks up [originalName] in the [_privateCache] cache of [library].
  /// If [originalName] was not renamed before, generate a new name.
  String _getPrivateName(LibraryElement library, String originalName) {
    return _privateCache.putIfAbsent(library, () => new Map<String, String>())
        .putIfAbsent(originalName,
                     () => _generateUniqueTopLevelName(originalName));
  }

  String _renameConstructor(ConstructorPlaceholder placeholder) {
    String name = placeholder.element.name;
    if (name == '') return "";
    String result = _renameGlobal(placeholder.element);
    return result;
  }

  String _renameGlobal(Entity entity) {
    assert(entity is! Element ||
           Elements.isErroneousElement(entity) ||
           Elements.isStaticOrTopLevel(entity) ||
           entity is TypeVariableElement);
    // TODO(smok): We may want to reuse class static field and method names.
    if (entity is Element) {
      LibraryElement library = entity.library;
      if (reexportingLibraries.containsKey(entity)) {
        library = reexportingLibraries[entity];
      }
      if (library.isPlatformLibrary) {
        if (library != _compiler.coreLibrary) {
          platformImports.add(library);
        }
        if (library.isInternalLibrary) {
          throw new SpannableAssertionFailure(entity,
              "Internal library $library should never have been imported from "
              "the code compiled by dart2dart.");
        }
        return entity.name;
      }
    }
    String name = _renamedCache.putIfAbsent(entity,
            () => _generateUniqueTopLevelName(entity.name));
    // Look up in [_renamedCache] for a name for [entity] .
    // If it was not renamed before, generate a new name.
    return name;
  }

  void _computeMinifiedRenames(PlaceholderCollector placeholderCollector) {
    _generator = new MinifyingGenerator();

    // Build a list sorted by usage of local nodes that will be renamed to
    // the same identifier. So the top-used local variables in all functions
    // will be renamed first and will all share the same new identifier.
    int maxLength = placeholderCollector.functionScopes.values.fold(0,
        (a, b) => max(a, b.localPlaceholders.length));

    List<Set<Node>> allLocals = new List<Set<Node>>
        .generate(maxLength, (_) => new Set<Node>());

    for (FunctionScope functionScope
        in placeholderCollector.functionScopes.values) {
      // Add current sorted local identifiers to the whole sorted list
      // of all local identifiers for all functions.
      List<LocalPlaceholder> currentSortedPlaceholders =
          sorted(functionScope.localPlaceholders,
              compareBy((LocalPlaceholder ph) => -ph.nodes.length));

      List<Set<Node>> currentSortedNodes = currentSortedPlaceholders
          .map((LocalPlaceholder ph) => ph.nodes).toList();

      for (int i = 0; i < currentSortedNodes.length; i++) {
        allLocals[i].addAll(currentSortedNodes[i]);
      }
    }

    // Rename elements, members and locals together based on their usage
    // count, otherwise when we rename elements first there will be no good
    // identifiers left for members even if they are used often.
    List<Renamable> renamables = new List<Renamable>();
    placeholderCollector.elementNodes.forEach(
        (Element element, Set<Node> nodes) {
      renamables.add(new GlobalRenamable(element, nodes));
    });
    placeholderCollector.memberPlaceholders.forEach(
        (String memberName, Set<Identifier> identifiers) {
      renamables.add(new MemberRenamable(memberName, identifiers));
    });
    for (Set<Node> localIdentifiers in allLocals) {
      renamables.add(new LocalRenamable(localIdentifiers));
    }
    renamables.sort();
    for (Renamable renamable in renamables) {
      String newName = renamable.createNewName(this);
      _renameNodes(renamable.nodes, (_) => newName);
    }
  }

  void _computeNonMinifiedRenames(PlaceholderCollector placeholderCollector) {
    _generator = new ConservativeGenerator();
    // Rename elements.
    placeholderCollector.elementNodes.forEach(
        (Element element, Set<Node> nodes) {
      _renameNodes(nodes, (_) => _renameGlobal(element));
    });

    // Rename locals.
    placeholderCollector.functionScopes.forEach(
        (functionElement, functionScope) {

      Set<String> memberIdentifiers = new Set<String>();
      Set<LocalPlaceholder> placeholders = functionScope.localPlaceholders;
      if (functionElement.enclosingClass != null) {
        functionElement.enclosingClass.forEachMember(
            (enclosingClass, member) {
              memberIdentifiers.add(member.name);
            });
      }
      Set<String> usedLocalIdentifiers = new Set<String>();
      for (LocalPlaceholder placeholder in placeholders) {
        String nextId = _generator.generate(placeholder.identifier, (name) {
          return functionScope.parameterIdentifiers.contains(name)
              || _forbiddenIdentifiers.contains(name)
              || usedLocalIdentifiers.contains(name)
              || memberIdentifiers.contains(name);
        });
        usedLocalIdentifiers.add(nextId);
        _renameNodes(placeholder.nodes, (_) => nextId);
      }
    });

    // Do not rename members to top-levels, that allows to avoid renaming
    // members to constructors.
    placeholderCollector.memberPlaceholders.forEach((identifier, nodes) {
      String newIdentifier = _generateMemberName(identifier);
      _renameNodes(nodes, (_) => newIdentifier);
    });
  }

  /// Finds renamings for all the placeholders in [placeholderCollector] and
  /// stores them in [renames].
  /// Also adds to [platformImports] all the platform-libraries that are used.
  void computeRenames(PlaceholderCollector placeholderCollector) {
    _allNamedParameterIdentifiers = new Set<String>();
    for (FunctionScope functionScope in
        placeholderCollector.functionScopes.values) {
      _allNamedParameterIdentifiers.addAll(functionScope.parameterIdentifiers);
    }

    _forbiddenIdentifiers = new Set<String>.from(fixedMemberNames);
    _forbiddenIdentifiers.addAll(Keyword.keywords.keys);
    _forbiddenIdentifiers.add('main');

    if (_compiler.enableMinification) {
      _computeMinifiedRenames(placeholderCollector);
    } else {
      _computeNonMinifiedRenames(placeholderCollector);
    }

    // Rename constructors.
    for (ConstructorPlaceholder placeholder in
        placeholderCollector.constructorPlaceholders) {
      renames[placeholder.node] =
          _renameConstructor(placeholder);
    };

    // Rename private identifiers uniquely for each library.
    placeholderCollector.privateNodes.forEach(
        (LibraryElement library, Set<Identifier> identifiers) {
      for (Identifier identifier in identifiers) {
        renames[identifier] = _getPrivateName(library, identifier.source);
      }
    });

    // Rename unresolved nodes, to make sure they still do not resolve.
    for (Node node in placeholderCollector.unresolvedNodes) {
      renames[node] = _generateUniqueTopLevelName('Unresolved');
    }

    // Erase prefixes that are now not needed.
    for (Node node in placeholderCollector.prefixNodesToErase) {
      renames[node] = '';
    }

    if (cutDeclarationTypes) {
      for (DeclarationTypePlaceholder placeholder in
           placeholderCollector.declarationTypePlaceholders) {
        renames[placeholder.typeNode] = placeholder.requiresVar ? 'var' : '';
      }
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

abstract class Generator {
  String generate(String originalName, bool isForbidden(String name));
}

/// Always tries to return original identifier name unless it is forbidden.
class ConservativeGenerator implements Generator {
  String generate(String originalName, bool isForbidden(String name)) {
    String result = originalName;
    int index = 0;
    while (isForbidden(result) ){ //|| result == originalName) {
      result = '${originalName}_${generateMiniId(index++)}';
    }
    return result;
  }
}

/// Always tries to generate the most compact identifier.
class MinifyingGenerator implements Generator {
  int index = 0;

  MinifyingGenerator();

  String generate(String originalName, bool isForbidden(String name)) {
    String result;
    do {
      result = generateMiniId(index++);
    } while (isForbidden(result));
    return result;
  }
}