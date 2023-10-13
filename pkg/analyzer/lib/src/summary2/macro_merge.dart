// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart' as ast;
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

  MacroElementsMerger({
    required this.partialUnits,
    required this.unitReference,
    required this.unitNode,
    required this.unitElement,
  });

  void perform() {
    _mergeClasses();
    _mergeUnitPropertyAccessors();
    _mergeUnitVariables();
  }

  void _mergeClasses() {
    for (final partialUnit in partialUnits) {
      for (final element in partialUnit.element.classes) {
        final reference = element.reference!;
        final containerRef = element.isAugmentation
            ? unitReference.getChild('@classAugmentation')
            : unitReference.getChild('@class');
        containerRef.addChildReference(element.name, reference);
      }
      unitElement.classes = [
        ...unitElement.classes,
        ...partialUnit.element.classes,
      ].toFixedList();
    }

    for (final node in unitNode.declarations) {
      if (node is ast.ClassDeclarationImpl) {
        final nameToken = node.name;
        final containerRef = node.augmentKeyword != null
            ? unitReference.getChild('@classAugmentation')
            : unitReference.getChild('@class');
        final reference = containerRef[nameToken.lexeme]!;
        final element = reference.element as ClassElementImpl;
        element.nameOffset = nameToken.offset;
      }
    }
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

    for (final node in unitNode.declarations) {
      if (node is ast.TopLevelVariableDeclaration) {
        for (final variable in node.variables.variables) {
          final nameToken = variable.name;
          final reference = containerRef[nameToken.lexeme]!;
          final element = reference.element as PropertyAccessorElementImpl;
          if (!element.isSynthetic) {
            element.nameOffset = nameToken.offset;
          }
        }
      }
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

    for (final node in unitNode.declarations) {
      if (node is ast.TopLevelVariableDeclaration) {
        for (final variable in node.variables.variables) {
          final nameToken = variable.name;
          final reference = containerRef[nameToken.lexeme]!;
          final element = reference.element as TopLevelVariableElementImpl;
          element.nameOffset = nameToken.offset;
        }
      }
    }
  }
}
