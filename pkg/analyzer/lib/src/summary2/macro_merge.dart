// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// Merges elements from [partialUnits] into [unitElement].
///
/// The [unitElement] is empty initially, but [unitNode] is not, and it is
/// built from the combined macro application results, closely but not exactly
/// corresponding to units from [partialUnits]. We use [unitNode] to update
/// offsets of the elements.
class MacroElementsMerger {
  final List<LinkingUnit> partialUnits;
  final Reference unitReference;
  final ast.CompilationUnit unitNode;
  final CompilationUnitElementImpl unitElement;
  final LibraryAugmentationElementImpl augmentation;

  MacroElementsMerger({
    required this.partialUnits,
    required this.unitReference,
    required this.unitNode,
    required this.unitElement,
    required this.augmentation,
  });

  void perform() {
    _rewriteImportPrefixes();
    _mergeClasses();
    _mergeFunctions();
    _mergeUnitPropertyAccessors();
    _mergeUnitVariables();
  }

  void _mergeClasses() {
    for (final partialUnit in partialUnits) {
      final elementsToAdd = <ClassElementImpl>[];
      for (final element in partialUnit.element.classes) {
        final reference = element.reference!;
        final containerRef = element.isAugmentation
            ? unitReference.getChild('@classAugmentation')
            : unitReference.getChild('@class');
        final existingRef = containerRef[element.name];
        if (existingRef == null) {
          elementsToAdd.add(element);
          containerRef.addChildReference(element.name, reference);
        } else {
          final existingElement = existingRef.element as ClassElementImpl;
          if (existingElement.augmentation == element) {
            existingElement.augmentation = null;
          }
          _mergeInstanceChildren(existingRef, existingElement, element);
        }
      }
      unitElement.classes = [
        ...unitElement.classes,
        ...elementsToAdd,
      ].toFixedList();
    }
  }

  void _mergeFunctions() {
    for (final partialUnit in partialUnits) {
      final elementsToAdd = <FunctionElementImpl>[];
      for (final element in partialUnit.element.functions) {
        final reference = element.reference!;
        final containerRef = element.isAugmentation
            ? unitReference.getChild('@functionAugmentation')
            : unitReference.getChild('@function');
        final existingRef = containerRef[element.name];
        if (existingRef == null) {
          elementsToAdd.add(element);
          containerRef.addChildReference(element.name, reference);
        } else {
          final existingElement = existingRef.element as FunctionElementImpl;
          if (existingElement.augmentation == element) {
            existingElement.augmentation = null;
          }
        }
      }
      unitElement.functions = [
        ...unitElement.functions,
        ...elementsToAdd,
      ].toFixedList();
    }
  }

  void _mergeInstanceChildren(
    Reference existingRef,
    InstanceElementImpl existingElement,
    InstanceElementImpl newElement,
  ) {
    if (existingElement is InterfaceElementImpl &&
        newElement is InterfaceElementImpl) {
      if (newElement.interfaces.isNotEmpty) {
        existingElement.interfaces = [
          ...existingElement.interfaces,
          ...newElement.interfaces
        ].toFixedList();
      }
    }

    final containerRef = existingRef.getChild('@method');
    for (final element in newElement.methods) {
      final reference = element.reference!;
      containerRef.addChildReference(element.name, reference);
    }
    existingElement.methods = [
      ...existingElement.methods,
      ...newElement.methods,
    ].toFixedList();

    // TODO(scheglov) accessors, fields
  }

  void _mergeUnitPropertyAccessors() {
    final containerRef = unitReference.getChild('@accessor');
    for (final partialUnit in partialUnits) {
      for (final element in partialUnit.element.accessors) {
        final reference = element.reference!;
        containerRef.addChildReference(element.name, reference);
      }
      unitElement.accessors = [
        ...unitElement.accessors,
        ...partialUnit.element.accessors,
      ].toFixedList();
    }
  }

  void _mergeUnitVariables() {
    final containerRef = unitReference.getChild('@topLevelVariable');
    for (final partialUnit in partialUnits) {
      for (final element in partialUnit.element.topLevelVariables) {
        final reference = element.reference!;
        containerRef.addChildReference(element.name, reference);
      }
      unitElement.topLevelVariables = [
        ...unitElement.topLevelVariables,
        ...partialUnit.element.topLevelVariables,
      ].toFixedList();
    }
  }

  void _rewriteImportPrefixes() {
    final uriToPartialPrefixes = <Uri, List<PrefixElementImpl>>{};
    for (final partialUnit in partialUnits) {
      for (final import in partialUnit.container.libraryImports) {
        final prefix = import.prefix?.element;
        final importedLibrary = import.importedLibrary;
        if (prefix != null && importedLibrary != null) {
          final uri = importedLibrary.source.uri;
          (uriToPartialPrefixes[uri] ??= []).add(prefix);
        }
      }
    }

    // The merged augmentation imports the same libraries, but with
    // different prefixes. Prepare the mapping.
    final partialPrefixToMerged =
        Map<PrefixElementImpl, PrefixElementImpl>.identity();
    for (final import in augmentation.libraryImports) {
      final prefix = import.prefix?.element;
      final importedLibrary = import.importedLibrary;
      if (prefix != null && importedLibrary != null) {
        final uri = importedLibrary.source.uri;
        final partialPrefixes = uriToPartialPrefixes[uri];
        if (partialPrefixes != null) {
          for (final partialPrefix in partialPrefixes) {
            partialPrefixToMerged[partialPrefix] = prefix;
          }
        }
      }
    }

    // Rewrite import prefixes in constants.
    final visitor = _RewriteImportPrefixes(partialPrefixToMerged);
    for (final partialUnit in partialUnits) {
      partialUnit.node.accept(visitor);
    }
  }
}

class _RewriteImportPrefixes extends RecursiveAstVisitor<void> {
  final Map<PrefixElementImpl, PrefixElementImpl> partialPrefixToMerged;

  _RewriteImportPrefixes(this.partialPrefixToMerged);

  @override
  void visitSimpleIdentifier(covariant ast.SimpleIdentifierImpl node) {
    final mergedPrefix = partialPrefixToMerged[node.staticElement];
    if (mergedPrefix != null) {
      // The name may be different in the merged augmentation.
      node.token = StringToken(
        TokenType.IDENTIFIER,
        mergedPrefix.name,
        -1,
      );
      // The element is definitely different.
      node.staticElement = mergedPrefix;
    }
  }
}
