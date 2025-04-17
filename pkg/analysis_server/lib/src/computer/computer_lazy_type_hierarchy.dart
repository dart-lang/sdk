// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analysis_server/src/search/type_hierarchy.dart';
library;

import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/utilities/element_location2.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart' hide ElementLocation;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/utilities/extensions/ast.dart';

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

  /// Finds subtypes for the [Element2] at [location].
  Future<List<TypeHierarchyRelatedItem>?> findSubtypes(
    ElementLocation location,
    SearchEngine searchEngine,
  ) async {
    var targetElement = await _findTargetElement(location);
    if (targetElement is! InterfaceElement2) {
      return null;
    }

    return _getSubtypes(targetElement, searchEngine);
  }

  /// Finds supertypes for the [Element2] at [location].
  ///
  /// If [anchor] is provided, it will be used to navigate to the element at
  /// [location] to preserve type arguments that have been provided along the
  /// way.
  ///
  /// Anchors are included in returned types (where necessary to preserve type
  /// arguments) that can be used when calling for the next level of types.
  Future<List<TypeHierarchyRelatedItem>?> findSupertypes(
    ElementLocation location, {
    TypeHierarchyAnchor? anchor,
  }) async {
    var targetElement = await _findTargetElement(location);
    if (targetElement == null) {
      return null;
    }
    var targetType = targetElement.thisType;

    // If we were provided an anchor, use it to re-locate the target type so
    // that any type arguments supplied along the way will be preserved in the
    // new node.
    if (anchor != null) {
      targetType =
          await _locateTargetFromAnchor(anchor, targetType) ?? targetType;
    }

    // If we had no existing anchor, create one that starts from this target as
    // the starting point for the new supertypes.
    anchor ??= TypeHierarchyAnchor(location: location, path: []);

    return _getSupertypes(targetType, anchor: anchor);
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
      if (element is InterfaceElement2) {
        type = element.thisType;
      }
    }

    return type is InterfaceType ? TypeHierarchyItem.forType(type) : null;
  }

  /// Locate the [Element2] referenced by [location].
  Future<InterfaceElement2?> _findTargetElement(
    ElementLocation location,
  ) async {
    var element = await location.locateIn(_result.session);
    return element is InterfaceElement2 ? element : null;
  }

  /// Gets immediate subtypes for the class/mixin [target].
  Future<List<TypeHierarchyRelatedItem>> _getSubtypes(
    InterfaceElement2 target,
    SearchEngine searchEngine,
  ) async {
    /// Helper to convert a [SearchMatch] to a [TypeHierarchyRelatedItem].
    TypeHierarchyRelatedItem? toHierarchyItem(SearchMatch match) {
      var element = match.element as InterfaceElement2;
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
    var seenElements = <Element2>{};
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
  List<TypeHierarchyRelatedItem> _getSupertypes(
    InterfaceType type, {
    TypeHierarchyAnchor? anchor,
  }) {
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

    if (anchor != null) {
      for (var (index, item) in supertypes.indexed) {
        // We only need to carry the anchor along if the supertype has type
        // arguments that we may be populating.
        if (item._type.typeArguments.isNotEmpty) {
          item._anchor = TypeHierarchyAnchor(
            location: anchor.location,
            path: [...anchor.path, index],
          );
        }
      }
    }

    return supertypes;
  }

  /// Returns whether [declaration] is a valid target for type hierarchy
  /// navigation.
  bool _isValidTargetDeclaration(AstNode? declaration) =>
      declaration is ClassDeclaration ||
      declaration is MixinDeclaration ||
      declaration is ExtensionTypeDeclaration ||
      declaration is EnumDeclaration;

  /// Navigate to [target] from [anchor], preserving type arguments supplied
  /// along the way.
  Future<InterfaceType?> _locateTargetFromAnchor(
    TypeHierarchyAnchor anchor,
    InterfaceType target,
  ) async {
    // Start from the anchor.
    var anchorElement = await _findTargetElement(anchor.location);
    var anchorPath = anchor.path;

    // Follow the provided path.
    var type = anchorElement?.thisType;
    for (int i = 0; i < anchorPath.length && type != null; i++) {
      var index = anchorPath[i];
      var supertypes = _getSupertypes(type);
      type = supertypes.length >= index + 1 ? supertypes[index]._type : null;
    }

    // Verify the element we arrived at matches the targetElement to guard
    // against code changes that made the path from the anchor invalid.
    return type != null && type.element3 == target.element3 ? type : null;
  }
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

  /// The type being displayed.
  final InterfaceType _type;

  /// The file that contains the declaration of this item.
  final String file;

  /// The range of the name at the declaration of this item.
  final SourceRange nameRange;

  /// The range of the code for the declaration of this item.
  final SourceRange codeRange;

  TypeHierarchyItem({
    required InterfaceType type,
    required this.displayName,
    required this.location,
    required this.file,
    required this.nameRange,
    required this.codeRange,
  }) : _type = type;

  TypeHierarchyItem._forType({
    required InterfaceType type,
    required this.location,
  }) : _type = type,
       displayName = _displayNameForType(type),
       nameRange = _nameRangeForElement(type.element3),
       codeRange = _codeRangeForElement(type.element3),
       file = type.element3.firstFragment.libraryFragment.source.fullName;

  static TypeHierarchyItem? forType(InterfaceType type) {
    var location = ElementLocation.forElement(type.element3);
    if (location == null) return null;

    return TypeHierarchyItem._forType(type: type, location: location);
  }

  /// Returns the [SourceRange] of the code for [element].
  static SourceRange _codeRangeForElement(Element2 element) {
    // Non-synthetic elements should always have code locations.
    var firstFragment = element.nonSynthetic2.firstFragment as ElementImpl;
    return SourceRange(firstFragment.codeOffset!, firstFragment.codeLength!);
  }

  /// Returns a name to display in the hierarchy for [type].
  static String _displayNameForType(InterfaceType type) {
    return type.getDisplayString();
  }

  /// Returns the [SourceRange] of the name for [element].
  static SourceRange _nameRangeForElement(Element2 element) {
    var fragment = element.nonSynthetic2.firstFragment;

    // Some non-synthetic items can still have invalid nameOffsets (for example
    // a compilation unit). This should never happen here, but guard against it.
    assert(fragment.nameOffset2 != -1);
    return fragment.nameOffset2 == -1
        ? SourceRange(0, 0)
        : SourceRange(fragment.nameOffset2 ?? 0, fragment.name2?.length ?? 0);
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

  TypeHierarchyAnchor? _anchor;

  TypeHierarchyRelatedItem({
    required super.type,
    required this.relationship,
    required super.displayName,
    required super.location,
    required super.file,
    required super.nameRange,
    required super.codeRange,
  });

  TypeHierarchyRelatedItem.forType({
    required super.type,
    required this.relationship,
    required super.location,
  }) : super._forType();

  /// An optional anchor element used to preserve type args.
  TypeHierarchyAnchor? get anchor => _anchor;

  static TypeHierarchyRelatedItem? constrainedTo(InterfaceType type) =>
      _forType(type, relationship: TypeHierarchyItemRelationship.constrainedTo);

  static TypeHierarchyRelatedItem? extends_(InterfaceType type) =>
      _forType(type, relationship: TypeHierarchyItemRelationship.extends_);

  static TypeHierarchyRelatedItem? implements(InterfaceType type) =>
      _forType(type, relationship: TypeHierarchyItemRelationship.implements);

  static TypeHierarchyRelatedItem? mixesIn(InterfaceType type) =>
      _forType(type, relationship: TypeHierarchyItemRelationship.mixesIn);

  static TypeHierarchyRelatedItem? unknown(InterfaceType type) =>
      _forType(type, relationship: TypeHierarchyItemRelationship.unknown);

  static TypeHierarchyRelatedItem? _forType(
    InterfaceType type, {
    required TypeHierarchyItemRelationship relationship,
  }) {
    var location = ElementLocation.forElement(type.element3);
    if (location == null) return null;

    return TypeHierarchyRelatedItem.forType(
      type: type,
      relationship: relationship,
      location: location,
    );
  }
}
