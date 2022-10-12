// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:collection/collection.dart';

/// A lazy computer for Type Hierarchies.
///
/// Unlike [TypeHierarchyComputer], this class computes hierarchies lazily and
/// roughly follow the LSP model, which is:
///
///   1. Client calls `findTarget(int offset)` to locate a starting point for
///      navigation.
///   2. Client passes the returned target into `findSubtypes()` or
///      `findSupertypes()` to find it's immediate sub/super types. This can be
///      repeated recursively.
///
/// It is expected that clients will call the methods above at different times
/// (as the user expands items in a tree). It is up to the caller to handle
/// cases where a target may no longer be valid (due to file modifications) that
/// may result in inconsistent results.
class DartLazyTypeHierarchyComputer {
  final ResolvedUnitResult _result;

  DartLazyTypeHierarchyComputer(this._result);

  /// Finds subtypes for [target].
  Future<List<TypeHierarchyItem>?> findSubtypes(
    TypeHierarchyItem target,
    SearchEngine searchEngine,
  ) async {
    final targetElement = _findTargetElement(target);
    if (targetElement is! InterfaceElement) {
      return null;
    }

    final subtypes = await _getSubtypes(targetElement, searchEngine);
    return _convert(subtypes);
  }

  /// Finds supertypes for [target].
  Future<List<TypeHierarchyItem>?> findSupertypes(
    TypeHierarchyItem target,
  ) async {
    final targetElement = _findTargetElement(target);
    if (targetElement == null) {
      return null;
    }

    final supertypes = _getSupertypes(targetElement);
    return _convert(supertypes);
  }

  /// Finds a target for starting type hierarchy navigation at [offset].
  TypeHierarchyItem? findTarget(int offset) {
    final node = NodeLocator2(offset).searchWithin(_result.unit);

    Element? element;

    // Try named types.
    final type = node?.thisOrAncestorOfType<NamedType>();
    element = type?.name.staticElement;

    if (element == null) {
      // Try enclosing class/mixins.
      final Declaration? declaration = node
          ?.thisOrAncestorMatching((node) => _isValidTargetDeclaration(node));
      element = declaration?.declaredElement;
    }

    return element != null ? TypeHierarchyItem.forElement(element) : null;
  }

  List<TypeHierarchyItem> _convert(List<InterfaceType> types) =>
      types.map((type) => TypeHierarchyItem.forElement(type.element)).toList();

  Element? _findTargetElement(TypeHierarchyItem target) {
    assert(target.file == _result.path);
    // Locate the element by name instead of offset since this call my occur
    // much later than the original find target request and it's possible the
    // user has made changes since.
    final targetElement = _result.unit.declarations
        .where(_isValidTargetDeclaration)
        .map((declaration) => declaration.declaredElement)
        .firstWhereOrNull((element) => element?.name == target.displayName);
    return targetElement;
  }

  /// Gets immediate sub types for the class/mixin [element].
  Future<List<InterfaceType>> _getSubtypes(
      InterfaceElement element, SearchEngine searchEngine) async {
    var matches = await searchEngine.searchSubtypes(element);
    return matches
        .map((match) => (match.element as InterfaceElement).thisType)
        .toList();
  }

  /// Gets immediate super types for the class/mixin [element].
  ///
  /// Includes all elements that contribute implementation to the type
  /// such as supertypes and mixins, but not interfaces, constraints or
  /// extended types.
  List<InterfaceType> _getSupertypes(Element element) {
    final supertype = element is InterfaceElement ? element.supertype : null;
    final mixins =
        element is InterfaceOrAugmentationElement ? element.mixins : null;
    return [
      if (supertype != null) supertype,
      ...?mixins,
    ];
  }

  /// Returns whether [declaration] is a valid target for type hierarchy
  /// navigation.
  bool _isValidTargetDeclaration(AstNode? declaration) =>
      // TODO(dantup): Should we handle `ClassAugmentationDeclaration`s?
      declaration is ClassDeclaration || declaration is MixinDeclaration;
}

/// An item that can appear in a Type Hierarchy.
class TypeHierarchyItem {
  /// The user-visible name for this item in the Type Hierarchy.
  final String displayName;

  /// The file that contains the declaration of this item.
  final String file;

  /// The range of the name at the declaration of this item.
  final SourceRange nameRange;

  /// The range of the code for the declaration of this item.
  final SourceRange codeRange;

  TypeHierarchyItem({
    required this.displayName,
    required this.file,
    required this.nameRange,
    required this.codeRange,
  });

  TypeHierarchyItem.forElement(Element element)
      : displayName = element.displayName,
        nameRange = _nameRangeForElement(element),
        codeRange = _codeRangeForElement(element),
        file = element.source!.fullName;

  /// Returns the [SourceRange] of the code for [element].
  static SourceRange _codeRangeForElement(Element element) {
    // Non-synthetic elements should always have code locations.
    final elementImpl = element.nonSynthetic as ElementImpl;
    return SourceRange(elementImpl.codeOffset!, elementImpl.codeLength!);
  }

  /// Returns the [SourceRange] of the name for [element].
  static SourceRange _nameRangeForElement(Element element) {
    element = element.nonSynthetic;

    // Some non-synthetic items can still have invalid nameOffsets (for example
    // a compilation unit). This should never happen here, but guard against it.
    assert(element.nameOffset != -1);
    return element.nameOffset == -1
        ? SourceRange(0, 0)
        : SourceRange(element.nameOffset, element.nameLength);
  }
}
