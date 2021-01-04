// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';

/// A visitor that visits ASTs and fills [UsedImportedElements].
class GatherUsedImportedElementsVisitor extends RecursiveAstVisitor {
  final LibraryElement library;
  final UsedImportedElements usedElements = UsedImportedElements();

  GatherUsedImportedElementsVisitor(this.library);

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    _recordAssignmentTarget(node, node.leftHandSide);
    return super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _recordIfExtensionMember(node.staticElement);
    return super.visitBinaryExpression(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _visitDirective(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _recordIfExtensionMember(node.staticElement);
    return super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _visitDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _recordIfExtensionMember(node.staticElement);
    return super.visitIndexExpression(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _visitDirective(node);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    _recordAssignmentTarget(node, node.operand);
    return super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _recordAssignmentTarget(node, node.operand);
    _recordIfExtensionMember(node.staticElement);
    return super.visitPrefixExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _visitIdentifier(node, node.staticElement);
  }

  void _recordAssignmentTarget(
    CompoundAssignmentExpression node,
    Expression target,
  ) {
    if (target is PrefixedIdentifier) {
      _visitIdentifier(target.identifier, node.readElement);
      _visitIdentifier(target.identifier, node.writeElement);
    } else if (target is PropertyAccess) {
      _visitIdentifier(target.propertyName, node.readElement);
      _visitIdentifier(target.propertyName, node.writeElement);
    } else if (target is SimpleIdentifier) {
      _visitIdentifier(target, node.readElement);
      _visitIdentifier(target, node.writeElement);
    }
  }

  void _recordIfExtensionMember(Element element) {
    if (element != null && element.enclosingElement is ExtensionElement) {
      _recordUsedExtension(element.enclosingElement);
    }
  }

  /// If the given [identifier] is prefixed with a [PrefixElement], fill the
  /// corresponding `UsedImportedElements.prefixMap` entry and return `true`.
  bool _recordPrefixMap(SimpleIdentifier identifier, Element element) {
    bool recordIfTargetIsPrefixElement(Expression target) {
      if (target is SimpleIdentifier && target.staticElement is PrefixElement) {
        List<Element> prefixedElements = usedElements.prefixMap
            .putIfAbsent(target.staticElement, () => <Element>[]);
        prefixedElements.add(element);
        return true;
      }
      return false;
    }

    AstNode parent = identifier.parent;
    if (parent is MethodInvocation && parent.methodName == identifier) {
      return recordIfTargetIsPrefixElement(parent.target);
    }
    if (parent is PrefixedIdentifier && parent.identifier == identifier) {
      return recordIfTargetIsPrefixElement(parent.prefix);
    }
    return false;
  }

  void _recordUsedElement(Element element) {
    // Ignore if an unknown library.
    LibraryElement containingLibrary = element.library;
    if (containingLibrary == null) {
      return;
    }
    // Ignore if a local element.
    if (library == containingLibrary) {
      return;
    }
    // Remember the element.
    usedElements.elements.add(element);
  }

  void _recordUsedExtension(ExtensionElement extension) {
    // Ignore if a local element.
    if (library == extension.library) {
      return;
    }
    // Remember the element.
    usedElements.usedExtensions.add(extension);
  }

  /// Visit identifiers used by the given [directive].
  void _visitDirective(Directive directive) {
    directive.documentationComment?.accept(this);
    directive.metadata.accept(this);
  }

  void _visitIdentifier(SimpleIdentifier identifier, Element element) {
    if (element == null) {
      return;
    }
    // Record `importPrefix.identifier` into 'prefixMap'.
    if (_recordPrefixMap(identifier, element)) {
      return;
    }
    Element enclosingElement = element.enclosingElement;
    if (enclosingElement is CompilationUnitElement) {
      _recordUsedElement(element);
    } else if (enclosingElement is ExtensionElement) {
      _recordUsedExtension(enclosingElement);
      return;
    } else if (element is PrefixElement) {
      usedElements.prefixMap.putIfAbsent(element, () => <Element>[]);
    } else if (element is MultiplyDefinedElement) {
      // If the element is multiply defined then call this method recursively
      // for each of the conflicting elements.
      List<Element> conflictingElements = element.conflictingElements;
      int length = conflictingElements.length;
      for (int i = 0; i < length; i++) {
        Element elt = conflictingElements[i];
        _visitIdentifier(identifier, elt);
      }
    }
  }
}

/// Instances of the class `ImportsVerifier` visit all of the referenced
/// libraries in the source code verifying that all of the imports are used,
/// otherwise a [HintCode.UNUSED_IMPORT] hint is generated with
/// [generateUnusedImportHints].
///
/// Additionally, [generateDuplicateImportHints] generates
/// [HintCode.DUPLICATE_IMPORT] hints and [HintCode.UNUSED_SHOWN_NAME] hints.
///
/// While this class does not yet have support for an "Organize Imports" action,
/// this logic built up in this class could be used for such an action in the
/// future.
class ImportsVerifier {
  /// All [ImportDirective]s of the current library.
  final List<ImportDirective> _allImports = <ImportDirective>[];

  /// A list of [ImportDirective]s that the current library imports, but does
  /// not use.
  ///
  /// As identifiers are visited by this visitor and an import has been
  /// identified as being used by the library, the [ImportDirective] is removed
  /// from this list. After all the sources in the library have been evaluated,
  /// this list represents the set of unused imports.
  ///
  /// See [ImportsVerifier.generateUnusedImportErrors].
  final List<ImportDirective> _unusedImports = <ImportDirective>[];

  /// After the list of [unusedImports] has been computed, this list is a proper
  /// subset of the unused imports that are listed more than once.
  final List<ImportDirective> _duplicateImports = <ImportDirective>[];

  /// The cache of [Namespace]s for [ImportDirective]s.
  final HashMap<ImportDirective, Namespace> _namespaceMap =
      HashMap<ImportDirective, Namespace>();

  /// This is a map between prefix elements and the import directives from which
  /// they are derived. In cases where a type is referenced via a prefix
  /// element, the import directive can be marked as used (removed from the
  /// unusedImports) by looking at the resolved `lib` in `lib.X`, instead of
  /// looking at which library the `lib.X` resolves.
  final HashMap<PrefixElement, List<ImportDirective>> _prefixElementMap =
      HashMap<PrefixElement, List<ImportDirective>>();

  /// A map of identifiers that the current library's imports show, but that the
  /// library does not use.
  ///
  /// Each import directive maps to a list of the identifiers that are imported
  /// via the "show" keyword.
  ///
  /// As each identifier is visited by this visitor, it is identified as being
  /// used by the library, and the identifier is removed from this map (under
  /// the import that imported it). After all the sources in the library have
  /// been evaluated, each list in this map's values present the set of unused
  /// shown elements.
  ///
  /// See [ImportsVerifier.generateUnusedShownNameHints].
  final HashMap<ImportDirective, List<SimpleIdentifier>> _unusedShownNamesMap =
      HashMap<ImportDirective, List<SimpleIdentifier>>();

  /// A map of names that are hidden more than once.
  final HashMap<NamespaceDirective, List<SimpleIdentifier>>
      _duplicateHiddenNamesMap =
      HashMap<NamespaceDirective, List<SimpleIdentifier>>();

  /// A map of names that are shown more than once.
  final HashMap<NamespaceDirective, List<SimpleIdentifier>>
      _duplicateShownNamesMap =
      HashMap<NamespaceDirective, List<SimpleIdentifier>>();

  void addImports(CompilationUnit node) {
    for (Directive directive in node.directives) {
      if (directive is ImportDirective) {
        LibraryElement libraryElement = directive.uriElement;
        if (libraryElement == null) {
          continue;
        }
        _allImports.add(directive);
        _unusedImports.add(directive);
        //
        // Initialize prefixElementMap
        //
        if (directive.asKeyword != null) {
          SimpleIdentifier prefixIdentifier = directive.prefix;
          if (prefixIdentifier != null) {
            Element element = prefixIdentifier.staticElement;
            if (element is PrefixElement) {
              List<ImportDirective> list = _prefixElementMap[element];
              if (list == null) {
                list = <ImportDirective>[];
                _prefixElementMap[element] = list;
              }
              list.add(directive);
            }
            // TODO (jwren) Can the element ever not be a PrefixElement?
          }
        }
        _addShownNames(directive);
      }
      if (directive is NamespaceDirective) {
        _addDuplicateShownHiddenNames(directive);
      }
    }
    if (_unusedImports.length > 1) {
      // order the list of unusedImports to find duplicates in faster than
      // O(n^2) time
      List<ImportDirective> importDirectiveArray =
          List<ImportDirective>.from(_unusedImports);
      importDirectiveArray.sort(ImportDirective.COMPARATOR);
      ImportDirective currentDirective = importDirectiveArray[0];
      for (int i = 1; i < importDirectiveArray.length; i++) {
        ImportDirective nextDirective = importDirectiveArray[i];
        if (ImportDirective.COMPARATOR(currentDirective, nextDirective) == 0) {
          // Add either the currentDirective or nextDirective depending on which
          // comes second, this guarantees that the first of the duplicates
          // won't be highlighted.
          if (currentDirective.offset < nextDirective.offset) {
            _duplicateImports.add(nextDirective);
          } else {
            _duplicateImports.add(currentDirective);
          }
        }
        currentDirective = nextDirective;
      }
    }
  }

  /// Any time after the defining compilation unit has been visited by this
  /// visitor, this method can be called to report an
  /// [HintCode.DUPLICATE_IMPORT] hint for each of the import directives in the
  /// [duplicateImports] list.
  ///
  /// @param errorReporter the error reporter to report the set of
  ///        [HintCode.DUPLICATE_IMPORT] hints to
  void generateDuplicateImportHints(ErrorReporter errorReporter) {
    int length = _duplicateImports.length;
    for (int i = 0; i < length; i++) {
      errorReporter.reportErrorForNode(
          HintCode.DUPLICATE_IMPORT, _duplicateImports[i].uri);
    }
  }

  /// Report a [HintCode.DUPLICATE_SHOWN_HIDDEN_NAME] hint for each duplicate
  /// shown or hidden name.
  ///
  /// Only call this method after all of the compilation units have been visited
  /// by this visitor.
  ///
  /// @param errorReporter the error reporter used to report the set of
  ///          [HintCode.UNUSED_SHOWN_NAME] hints
  void generateDuplicateShownHiddenNameHints(ErrorReporter reporter) {
    _duplicateHiddenNamesMap.forEach(
        (NamespaceDirective directive, List<SimpleIdentifier> identifiers) {
      int length = identifiers.length;
      for (int i = 0; i < length; i++) {
        Identifier identifier = identifiers[i];
        reporter.reportErrorForNode(
            HintCode.DUPLICATE_HIDDEN_NAME, identifier, [identifier.name]);
      }
    });
    _duplicateShownNamesMap.forEach(
        (NamespaceDirective directive, List<SimpleIdentifier> identifiers) {
      int length = identifiers.length;
      for (int i = 0; i < length; i++) {
        Identifier identifier = identifiers[i];
        reporter.reportErrorForNode(
            HintCode.DUPLICATE_SHOWN_NAME, identifier, [identifier.name]);
      }
    });
  }

  /// Report an [HintCode.UNUSED_IMPORT] hint for each unused import.
  ///
  /// Only call this method after all of the compilation units have been visited
  /// by this visitor.
  ///
  /// @param errorReporter the error reporter used to report the set of
  ///        [HintCode.UNUSED_IMPORT] hints
  void generateUnusedImportHints(ErrorReporter errorReporter) {
    int length = _unusedImports.length;
    for (int i = 0; i < length; i++) {
      ImportDirective unusedImport = _unusedImports[i];
      // Check that the imported URI exists and isn't dart:core
      ImportElement importElement = unusedImport.element;
      if (importElement != null) {
        LibraryElement libraryElement = importElement.importedLibrary;
        if (libraryElement == null ||
            libraryElement.isDartCore ||
            libraryElement.isSynthetic) {
          continue;
        }
      }
      StringLiteral uri = unusedImport.uri;
      errorReporter
          .reportErrorForNode(HintCode.UNUSED_IMPORT, uri, [uri.stringValue]);
    }
  }

  /// Use the error [reporter] to report an [HintCode.UNUSED_SHOWN_NAME] hint
  /// for each unused shown name.
  ///
  /// This method should only be invoked after all of the compilation units have
  /// been visited by this visitor.
  void generateUnusedShownNameHints(ErrorReporter reporter) {
    _unusedShownNamesMap.forEach(
        (ImportDirective importDirective, List<SimpleIdentifier> identifiers) {
      if (_unusedImports.contains(importDirective)) {
        // The whole import is unused, not just one or more shown names from it,
        // so an "unused_import" hint will be generated, making it unnecessary
        // to generate hints for the individual names.
        return;
      }
      int length = identifiers.length;
      for (int i = 0; i < length; i++) {
        Identifier identifier = identifiers[i];
        List<SimpleIdentifier> duplicateNames =
            _duplicateShownNamesMap[importDirective];
        if (duplicateNames == null || !duplicateNames.contains(identifier)) {
          // Only generate a hint if we won't also generate a
          // "duplicate_shown_name" hint for the same identifier.
          reporter.reportErrorForNode(
              HintCode.UNUSED_SHOWN_NAME, identifier, [identifier.name]);
        }
      }
    });
  }

  /// Remove elements from [_unusedImports] using the given [usedElements].
  void removeUsedElements(UsedImportedElements usedElements) {
    bool everythingIsKnownToBeUsed() =>
        _unusedImports.isEmpty && _unusedShownNamesMap.isEmpty;

    // Process import prefixes.
    usedElements.prefixMap
        .forEach((PrefixElement prefix, List<Element> elements) {
      if (everythingIsKnownToBeUsed()) {
        return;
      }
      // Find import directives using namespaces.
      for (var importDirective in _prefixElementMap[prefix] ?? []) {
        Namespace namespace = _computeNamespace(importDirective);
        if (elements.isEmpty) {
          // [prefix] and [elements] were added to [usedElements.prefixMap] but
          // [elements] is empty, so the prefix was referenced incorrectly.
          // Another diagnostic about the prefix reference is reported, and we
          // shouldn't confuse by also reporting an unused prefix.
          _unusedImports.remove(importDirective);
        }
        for (var element in elements) {
          if (namespace?.getPrefixed(prefix.name, element.name) != null) {
            _unusedImports.remove(importDirective);
            _removeFromUnusedShownNamesMap(element, importDirective);
          }
        }
      }
    });
    // Process top-level elements.
    for (Element element in usedElements.elements) {
      if (everythingIsKnownToBeUsed()) {
        return;
      }
      // Find import directives using namespaces.
      for (ImportDirective importDirective in _allImports) {
        Namespace namespace = _computeNamespace(importDirective);
        if (namespace?.get(element.name) != null) {
          _unusedImports.remove(importDirective);
          _removeFromUnusedShownNamesMap(element, importDirective);
        }
      }
    }
    // Process extension elements.
    for (ExtensionElement extensionElement in usedElements.usedExtensions) {
      if (everythingIsKnownToBeUsed()) {
        return;
      }
      // Find import directives using namespaces.
      for (ImportDirective importDirective in _allImports) {
        Namespace namespace = _computeNamespace(importDirective);
        var prefix = importDirective.prefix?.name;
        var elementName = extensionElement.name;
        if (prefix == null) {
          if (namespace?.get(elementName) == extensionElement) {
            _unusedImports.remove(importDirective);
            _removeFromUnusedShownNamesMap(extensionElement, importDirective);
          }
        } else {
          // An extension might be used solely because one or more instance
          // members are referenced, which does not require explicit use of the
          // prefix. We still indicate that the import directive is used.
          if (namespace?.getPrefixed(prefix, elementName) == extensionElement) {
            _unusedImports.remove(importDirective);
            _removeFromUnusedShownNamesMap(extensionElement, importDirective);
          }
        }
      }
    }
  }

  /// Add duplicate shown and hidden names from [directive] into
  /// [_duplicateHiddenNamesMap] and [_duplicateShownNamesMap].
  void _addDuplicateShownHiddenNames(NamespaceDirective directive) {
    if (directive.combinators == null) {
      return;
    }
    for (Combinator combinator in directive.combinators) {
      // Use a Set to find duplicates in faster than O(n^2) time.
      Set<Element> identifiers = <Element>{};
      if (combinator is HideCombinator) {
        for (SimpleIdentifier name in combinator.hiddenNames) {
          if (name.staticElement != null) {
            if (!identifiers.add(name.staticElement)) {
              // [name] is a duplicate.
              List<SimpleIdentifier> duplicateNames = _duplicateHiddenNamesMap
                  .putIfAbsent(directive, () => <SimpleIdentifier>[]);
              duplicateNames.add(name);
            }
          }
        }
      } else if (combinator is ShowCombinator) {
        for (SimpleIdentifier name in combinator.shownNames) {
          if (name.staticElement != null) {
            if (!identifiers.add(name.staticElement)) {
              // [name] is a duplicate.
              List<SimpleIdentifier> duplicateNames = _duplicateShownNamesMap
                  .putIfAbsent(directive, () => <SimpleIdentifier>[]);
              duplicateNames.add(name);
            }
          }
        }
      }
    }
  }

  /// Add every shown name from [importDirective] into [_unusedShownNamesMap].
  void _addShownNames(ImportDirective importDirective) {
    if (importDirective.combinators == null) {
      return;
    }
    List<SimpleIdentifier> identifiers = <SimpleIdentifier>[];
    _unusedShownNamesMap[importDirective] = identifiers;
    for (Combinator combinator in importDirective.combinators) {
      if (combinator is ShowCombinator) {
        for (SimpleIdentifier name in combinator.shownNames) {
          if (name.staticElement != null) {
            identifiers.add(name);
          }
        }
      }
    }
  }

  /// Lookup and return the [Namespace] from the [_namespaceMap].
  ///
  /// If the map does not have the computed namespace, compute it and cache it
  /// in the map. If [importDirective] is not resolved or is not resolvable,
  /// `null` is returned.
  ///
  /// @param importDirective the import directive used to compute the returned
  ///        namespace
  /// @return the computed or looked up [Namespace]
  Namespace _computeNamespace(ImportDirective importDirective) {
    Namespace namespace = _namespaceMap[importDirective];
    if (namespace == null) {
      // If the namespace isn't in the namespaceMap, then compute and put it in
      // the map.
      ImportElement importElement = importDirective.element;
      if (importElement != null) {
        namespace = importElement.namespace;
        _namespaceMap[importDirective] = namespace;
      }
    }
    return namespace;
  }

  /// Remove [element] from the list of names shown by [importDirective].
  void _removeFromUnusedShownNamesMap(
      Element element, ImportDirective importDirective) {
    List<SimpleIdentifier> identifiers = _unusedShownNamesMap[importDirective];
    if (identifiers == null) {
      return;
    }
    int length = identifiers.length;
    for (int i = 0; i < length; i++) {
      Identifier identifier = identifiers[i];
      if (element is PropertyAccessorElement) {
        // If the getter or setter of a variable is used, then the variable (the
        // shown name) is used.
        if (identifier.staticElement == element.variable) {
          identifiers.remove(identifier);
          break;
        }
      } else {
        if (identifier.staticElement == element) {
          identifiers.remove(identifier);
          break;
        }
      }
    }
    if (identifiers.isEmpty) {
      _unusedShownNamesMap.remove(importDirective);
    }
  }
}

/// A container with information about used imports prefixes and used imported
/// elements.
class UsedImportedElements {
  /// The map of referenced prefix elements and the elements that they prefix.
  final Map<PrefixElement, List<Element>> prefixMap = {};

  /// The set of referenced top-level elements.
  final Set<Element> elements = {};

  /// The set of extensions defining members that are referenced.
  final Set<ExtensionElement> usedExtensions = {};
}
