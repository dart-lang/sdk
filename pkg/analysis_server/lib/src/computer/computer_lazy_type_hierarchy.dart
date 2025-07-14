// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analysis_server/src/search/type_hierarchy.dart';
library;

import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/utilities/element_location2.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/element/element.dart';

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

  /// Finds subtypes for the [Element] at [location].
  Future<List<TypeHierarchyRelatedItem>?> findSubtypes(
    ElementLocation location,
    SearchEngine searchEngine,
  ) async {
    var targetElement = await _findTargetElement(location);
    if (targetElement is! InterfaceElement) {
      return null;
    }

    return _getSubtypes(targetElement, searchEngine);
  }

  /// Finds supertypes for the [Element] at [location].
  Future<List<TypeHierarchyRelatedItem>?> findSupertypes(
    ElementLocation location,
  ) async {
    var targetElement = await _findTargetElement(location);
    if (targetElement == null) {
      return null;
    }
    var targetType = targetElement.thisType;

    return _getSupertypes(targetType);
  }

  /// Finds a target for starting type hierarchy navigation at [offset].
  TypeHierarchyItem? findTarget(int offset) {
    var node = _result.unit.nodeCovering(offset: offset);

    DartType? type;

    // Try named types.
    type = node?.thisOrAncestorOfType<NamedType>()?.type;

    if (type == null) {
      // Try enclosing class/mixins.
      Declaration? declaration = node?.thisOrAncestorMatching(
        (node) => _isValidTargetDeclaration(node),
      );
      var element = declaration?.declaredFragment?.element;
      if (element is InterfaceElement) {
        type = element.thisType;
      }
    }

    return type is InterfaceType
        ? TypeHierarchyItem.forElement(type.element)
        : null;
  }

  /// Locate the [Element] referenced by [location].
  Future<InterfaceElement?> _findTargetElement(ElementLocation location) async {
    var element = await location.locateIn(_result.session);
    return element is InterfaceElement ? element : null;
  }

  /// Gets immediate subtypes for the class/mixin [target].
  Future<List<TypeHierarchyRelatedItem>> _getSubtypes(
    InterfaceElement target,
    SearchEngine searchEngine,
  ) async {
    /// Helper to convert a [SearchMatch] to a [TypeHierarchyRelatedItem].
    TypeHierarchyRelatedItem? toHierarchyItem(SearchMatch match) {
      var element = match.element as InterfaceElement;
      var type = element.thisType;
      switch (match.kind) {
        case MatchKind.REFERENCE_IN_EXTENDS_CLAUSE:
          return TypeHierarchyRelatedItem.extends_(type);
        case MatchKind.REFERENCE_IN_IMPLEMENTS_CLAUSE:
          return TypeHierarchyRelatedItem.implements(type);
        case MatchKind.REFERENCE_IN_ON_CLAUSE:
          return TypeHierarchyRelatedItem.constrainedTo(type);
        case MatchKind.REFERENCE_IN_WITH_CLAUSE:
          return TypeHierarchyRelatedItem.mixesIn(type);
        default:
          assert(false, 'Subtype found with unknown relationship type');
          return TypeHierarchyRelatedItem.unknown(type);
      }
    }

    var matches = await searchEngine.searchSubtypes(
      target,
      SearchEngineCache(),
    );
    var seenElements = <Element>{};
    return matches
        .where((match) => seenElements.add(match.element))
        .map(toHierarchyItem)
        .nonNulls
        .toList();
  }

  /// Gets immediate super types for the class/mixin [type].
  ///
  /// Includes all elements that contribute implementation to the type
  /// such as supertypes and mixins, but not interfaces, constraints or
  /// extended types.
  List<TypeHierarchyRelatedItem> _getSupertypes(InterfaceType type) {
    var supertype = type.superclass;
    var interfaces = type.interfaces;
    var mixins = type.mixins;
    var superclassConstraints = type.superclassConstraints;

    var supertypes =
        [
          if (supertype != null) TypeHierarchyRelatedItem.extends_(supertype),
          ...superclassConstraints.map(TypeHierarchyRelatedItem.constrainedTo),
          ...interfaces.map(TypeHierarchyRelatedItem.implements),
          ...mixins.map(TypeHierarchyRelatedItem.mixesIn),
        ].nonNulls.toList();

    return supertypes;
  }

  /// Returns whether [declaration] is a valid target for type hierarchy
  /// navigation.
  bool _isValidTargetDeclaration(AstNode? declaration) =>
      declaration is ClassDeclaration ||
      declaration is MixinDeclaration ||
      declaration is ExtensionTypeDeclaration ||
      declaration is EnumDeclaration;
}

class TypeHierarchyAnchor {
  /// The location of the anchor element.
  final ElementLocation location;

  /// The supertype path from [location] to the target element.
  final List<int> path;

  TypeHierarchyAnchor({required this.location, required this.path});
}

/// An item that can appear in a Type Hierarchy.
class TypeHierarchyItem {
  /// The user-visible name for this item in the Type Hierarchy.
  final String displayName;

  /// The location of the element being displayed.
  ///
  /// This is used to re-locate the element when calling
  /// `findSubtypes`/`findSupertypes` so that if code has been modified since
  /// the `findTarget` call the element can still be located (provided the
  /// names/identifiers have not changed).
  final ElementLocation location;

  /// The file that contains the declaration of this item.
  final String file;

  /// The range of the name at the declaration of this item.
  final SourceRange nameRange;

  /// The range of the code for the declaration of this item.
  final SourceRange codeRange;

  TypeHierarchyItem({
    required this.displayName,
    required this.location,
    required this.file,
    required this.nameRange,
    required this.codeRange,
  });

  TypeHierarchyItem._forElement({
    required InterfaceElement element,
    required this.location,
  }) : displayName = _displayNameForElement(element),
       nameRange = _nameRangeForElement(element),
       codeRange = _codeRangeForElement(element),
       file = element.firstFragment.libraryFragment.source.fullName;

  static TypeHierarchyItem? forElement(InterfaceElement element) {
    var location = ElementLocation.forElement(element);
    if (location == null) return null;

    return TypeHierarchyItem._forElement(element: element, location: location);
  }

  /// Returns the [SourceRange] of the code for [element].
  static SourceRange _codeRangeForElement(Element element) {
    // Non-synthetic elements should always have code locations.
    var firstFragment = element.nonSynthetic.firstFragment as FragmentImpl;
    return SourceRange(firstFragment.codeOffset!, firstFragment.codeLength!);
  }

  /// Returns a name to display in the hierarchy for [element].
  static String _displayNameForElement(InterfaceElement element) {
    return element.baseElement.thisType.getDisplayString();
  }

  /// Returns the [SourceRange] of the name for [element].
  static SourceRange _nameRangeForElement(Element element) {
    var fragment = element.nonSynthetic.firstFragment;

    // Some non-synthetic items can still have invalid nameOffsets (for example
    // a compilation unit). This should never happen here, but guard against it.
    assert(fragment.nameOffset != -1);
    return fragment.nameOffset == -1
        ? SourceRange(0, 0)
        : SourceRange(fragment.nameOffset ?? 0, fragment.name?.length ?? 0);
  }
}

enum TypeHierarchyItemRelationship {
  unknown,
  implements,
  extends_,
  constrainedTo,
  mixesIn,
}

/// A supertype or subtype of a [TypeHierarchyItem].
class TypeHierarchyRelatedItem extends TypeHierarchyItem {
  /// The relationship this item has with the target item.
  final TypeHierarchyItemRelationship relationship;

  TypeHierarchyRelatedItem.forElement({
    required super.element,
    required this.relationship,
    required super.location,
  }) : super._forElement();

  static TypeHierarchyRelatedItem? constrainedTo(InterfaceType type) =>
      _forElement(
        type.element,
        relationship: TypeHierarchyItemRelationship.constrainedTo,
      );

  static TypeHierarchyRelatedItem? extends_(InterfaceType type) => _forElement(
    type.element,
    relationship: TypeHierarchyItemRelationship.extends_,
  );

  static TypeHierarchyRelatedItem? implements(InterfaceType type) =>
      _forElement(
        type.element,
        relationship: TypeHierarchyItemRelationship.implements,
      );

  static TypeHierarchyRelatedItem? mixesIn(InterfaceType type) => _forElement(
    type.element,
    relationship: TypeHierarchyItemRelationship.mixesIn,
  );

  static TypeHierarchyRelatedItem? unknown(InterfaceType type) => _forElement(
    type.element,
    relationship: TypeHierarchyItemRelationship.unknown,
  );

  static TypeHierarchyRelatedItem? _forElement(
    InterfaceElement element, {
    required TypeHierarchyItemRelationship relationship,
  }) {
    var location = ElementLocation.forElement(element);
    if (location == null) return null;

    return TypeHierarchyRelatedItem.forElement(
      element: element,
      relationship: relationship,
      location: location,
    );
  }
}
