// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/search/element_references.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// Returns the container for [element] that should be used in Call Hierarchy.
///
/// Returns `null` if none of [element]'s ancestors are valid containers.
///
/// This is used to construct (and group calls by) a [CallHierarchyItem] that
/// contains calls and also locate their containers for additional labelling.
Element? _getContainer(Element element) {
  // TODO(brianwilkerson): This used to use the compilation unit as a container
  //  which allowed users to see the path to the containing file, but that's
  //  been lost. Consider trying to restore that behavior.
  const containerKinds = {
    ElementKind.CLASS,
    ElementKind.LIBRARY,
    ElementKind.CONSTRUCTOR,
    ElementKind.ENUM,
    ElementKind.EXTENSION,
    ElementKind.EXTENSION_TYPE,
    ElementKind.FUNCTION,
    ElementKind.GETTER,
    ElementKind.METHOD,
    ElementKind.MIXIN,
    ElementKind.SETTER,
  };
  return element.thisOrAncestorMatching(
    (ancestor) => containerKinds.contains(ancestor.kind),
  );
}

/// Gets a user-friendly display name for [element].
String _getDisplayName(Element element) {
  return switch (element) {
    LibraryElement() => element.firstFragment.source.shortName,
    GetterElement() => 'get ${element.displayName}',
    SetterElement() => 'set ${element.displayName}',
    _ => element.displayName,
  };
}

/// A [CallHierarchyItem] and a set of ranges that call to or from it.
class CallHierarchyCalls {
  final CallHierarchyItem item;
  final List<SourceRange> ranges = [];

  CallHierarchyCalls(this.item);
}

/// An item that can appear in a Call Hierarchy.
///
/// Items are the containers that can contain calls to other items. This
/// includes not only functions and methods, but classes (because they can call
/// functions in class field initializers) and files (because they can call
/// functions in top level variable initializers).
///
/// Implicit constructors are represented using the location of their classes
/// (since do not themselves have a range) but a [kind] of
/// [CallHierarchyKind.constructor].
class CallHierarchyItem {
  /// The kind of this item in the Call Hierarchy.
  ///
  /// This may be used to select an icon to show in the Call Hierarchy tree.
  final CallHierarchyKind kind;

  /// The user-visible name for this item in the Call Hierarchy.
  final String displayName;

  /// The user-visible name for the container of this item in the Call
  /// Hierarchy.
  ///
  /// `null` if this item does not have a named container.
  late final String? containerName;

  /// The file that contains the declaration of this item.
  final String file;

  /// The range of the name at the declaration of this item.
  final SourceRange nameRange;

  /// The range of the code for the declaration of this item.
  final SourceRange codeRange;

  CallHierarchyItem({
    required this.displayName,
    required this.containerName,
    required this.kind,
    required this.file,
    required this.nameRange,
    required this.codeRange,
  });

  CallHierarchyItem.forElement(Element element)
    : displayName = _getDisplayName(element),
      nameRange = _nameRangeForElement(element),
      codeRange = _codeRangeForElement(element),
      file = element.firstFragment.libraryFragment!.source.fullName,
      kind = CallHierarchyKind.forElement(element) {
    var enclosingElement =
        element.enclosingElement ??
        element.firstFragment.enclosingFragment?.element;
    var container = enclosingElement != null
        ? _getContainer(enclosingElement)
        : null;
    containerName = container != null ? _getDisplayName(container) : null;
  }

  /// Returns the [SourceRange] of the code for [element].
  static SourceRange _codeRangeForElement(Element element) {
    // For synthetic items (like implicit constructors), use the nonSynthetic
    // element for the location.
    element = element.nonSynthetic;
    var fragment = element.firstFragment as FragmentImpl;

    // Non-synthetic elements should always have code locations.
    // TODO(brianwilkerson): Figure out why that's no longer true and possibly
    //  remove the conditionals below.
    return SourceRange(fragment.codeOffset ?? 0, fragment.codeLength ?? 0);
  }

  /// Returns the [SourceRange] of the name for [element].
  static SourceRange _nameRangeForElement(Element element) {
    // For synthetic items (like implicit constructors), use the nonSynthetic
    // element for the location.
    element = element.nonSynthetic;
    var fragment = element.firstFragment as FragmentImpl;

    var nameOffset = fragment.nameOffset;
    var nameEnd = fragment.nameEnd;
    if (nameOffset != null && nameEnd != null) {
      return SourceRange(nameOffset, nameEnd - nameOffset);
    }

    // For default constructors, use the type name or new/factory keyword.
    if (fragment is ConstructorFragmentImpl) {
      var typeNameOffset = fragment.typeNameOffset;
      var typeName = fragment.typeName;
      var newKeywordOffset = fragment.newKeywordOffset;
      var factoryKeywordOffset = fragment.factoryKeywordOffset;
      if (typeName != null && typeNameOffset != null) {
        return SourceRange(typeNameOffset, typeName.length);
      } else if (newKeywordOffset != null) {
        return SourceRange(newKeywordOffset, 'new'.length);
      } else if (factoryKeywordOffset != null) {
        return SourceRange(factoryKeywordOffset, 'factory'.length);
      }
    }

    return SourceRange(0, 0);
  }
}

/// Kinds of [CallHierarchyItem] that can make calls to other
/// [CallHierarchyItem]s.
enum CallHierarchyKind {
  class_,
  constructor,
  extension,
  file,
  function,
  method,
  mixin,
  property,
  unknown;

  static const _elementMapping = {
    ElementKind.CLASS: class_,
    ElementKind.LIBRARY: file,
    ElementKind.CONSTRUCTOR: constructor,
    ElementKind.EXTENSION: extension,
    ElementKind.FUNCTION: function,
    ElementKind.GETTER: property,
    ElementKind.METHOD: method,
    ElementKind.MIXIN: mixin,
    ElementKind.SETTER: property,
  };

  static CallHierarchyKind forElement(Element element) =>
      _elementMapping[element.kind] ?? unknown;
}

/// A computer for Call Hierarchies.
///
/// Call Hierarchies are computed lazily and roughly follow the LSP model, which
/// is:
///
///   1. Client calls `findTarget(int offset)` to locate a starting point for
///      navigation. The starting point is always based on the declaration of
///      the executable code even if invoked at a call site.
///   2. Client passes the returned target into `findIncomingCalls()` or
///      `findOutgoingCalls()` to find relevant calls in to/out of that item.
///      The result will contain a set of other items, along with the ranges
///      of the calls in or out.
///
/// It is expected that clients will call the methods above at different times
/// (as the user expands items in a tree). It is up to the caller to handle
/// cases where a target may no longer be valid (due to file modifications) that
/// may result in inconsistent results.
class DartCallHierarchyComputer {
  final ResolvedUnitResult _result;

  DartCallHierarchyComputer(this._result);

  /// Finds incoming calls to [target], returning the elements that call them
  /// and ranges of those calls within.
  ///
  /// Returns an empty list if [target] is not valid, including if source code
  /// has changed and its offset is no longer correct.
  Future<List<CallHierarchyCalls>> findIncomingCalls(
    CallHierarchyItem target,
    SearchEngine searchEngine,
  ) async {
    assert(target.file == _result.path);
    var node = _findTargetNode(target.nameRange.offset);
    var element = _getElementOfNode(node);
    if (element == null || !_isMatchingElement(element, target)) {
      return [];
    }

    // Implicit constructors are handled using the Class element and a kind of
    // `constructor`, because we need to locate them using an `offset`, which
    // implicit constructors do not have.
    // Here, we map them back to the synthetic constructor element.
    var isImplicitConstructor =
        element is InterfaceElement &&
        target.kind == CallHierarchyKind.constructor;
    if (isImplicitConstructor) {
      element = element.unnamedConstructor;
    }

    // We only find incoming calls to executable elements.
    if (element is! ExecutableElement) {
      return [];
    }

    var computer = ElementReferencesComputer(searchEngine);
    var references = await computer.compute(element, false);

    // Group results by their container, since we only want to return a single
    // entry for a body, with a set of ranges within.
    var resultsByContainer = <Element, CallHierarchyCalls>{};
    // We may need to fetch parsed results for the other files; reuse them
    // across calls.
    var parsedUnits = <String, SomeParsedUnitResult?>{};
    for (var reference in references) {
      var container = _getContainer(reference.element);
      if (container == null) {
        continue;
      }

      // Create an item for a container the first time we see it.
      var containerCalls = resultsByContainer.putIfAbsent(
        container,
        () => CallHierarchyCalls(CallHierarchyItem.forElement(container)),
      );

      // Add this match to the containers results.
      var range = _rangeForSearchMatch(reference, parsedUnits);
      containerCalls.ranges.add(range);
    }

    return resultsByContainer.values.toList();
  }

  /// Finds outgoing calls from [target], returning the elements that are called
  /// and the ranges that call them.
  ///
  /// Returns an empty list if [target] is not valid, including if source code
  /// has changed and its offset is no longer correct.
  Future<List<CallHierarchyCalls>> findOutgoingCalls(
    CallHierarchyItem target,
  ) async {
    assert(target.file == _result.path);
    var node = _findTargetNode(target.nameRange.offset);
    var element = _getElementOfNode(node);
    if (node == null ||
        element == null ||
        !_isMatchingElement(element, target)) {
      return [];
    }

    // If invoked on a primary constructor declaration, we need to visit the
    // body to find outgoing calls.
    if (node case PrimaryConstructorDeclaration(:var body?)) {
      node = body;
    }

    // Don't look for outbound calls in things that aren't functions.
    if (!(node is FunctionDeclaration ||
        node is ConstructorDeclaration ||
        node is MethodDeclaration ||
        node is PrimaryConstructorBody)) {
      return [];
    }

    var referenceNodes = <AstNode>{};
    node.accept(_OutboundCallVisitor(node, referenceNodes.add));

    // Group results by their target, since we only want to return a single
    // entry for each target, with a set of ranges that call it.
    var resultsByTarget = <Element, CallHierarchyCalls>{};
    for (var referenceNode in referenceNodes) {
      var target = _getElementOfNode(referenceNode);
      if (target == null) {
        continue;
      }

      // Create an item for a target the first time we see it.
      var calls = resultsByTarget.putIfAbsent(
        target,
        () => CallHierarchyCalls(CallHierarchyItem.forElement(target)),
      );

      // Add this call to the targets results.
      var range = _rangeForNode(referenceNode);
      calls.ranges.add(range);
    }

    return resultsByTarget.values.toList();
  }

  /// Finds a target for starting call hierarchy navigation at [offset].
  ///
  /// If [offset] is an invocation, returns information about the [Element] it
  /// refers to.
  CallHierarchyItem? findTarget(int offset) {
    var node = _findTargetNode(offset);
    var element = _getElementOfNode(node);

    // We only return targets that are executable elements.
    return element is ExecutableElement
        ? CallHierarchyItem.forElement(element)
        : null;
  }

  /// Finds a target node for call hierarchy navigation at [offset].
  AstNode? _findTargetNode(int offset) {
    var node = _result.unit.nodeCovering(offset: offset);

    // For consistency with other places, we only treat the type name as the
    // constructor for default constructor (since we use the constructors name
    // as the target otherwise).
    return switch (node) {
      // Type name in a named constructor reference; not considered a call.
      NamedType(parent: ConstructorName(:var name?))
          when offset < name.offset =>
        null,
      // Type name in a named constructor declaration; not considered a call.
      Identifier(parent: ConstructorDeclaration(:var name?))
          when offset < name.offset =>
        null,
      // Type name in a default constructor declaration, or constructor name in
      // a named constructor; use the constructor.
      Identifier(parent: ConstructorDeclaration(name: null)) => node.parent,
      // Type name in a named primary constructor declaration; not considered a
      // call.
      PrimaryConstructorDeclaration(:var constructorName?)
          when offset < constructorName.name.offset =>
        null,
      // Primary constructor name; use the constructor.
      PrimaryConstructorName() => node.parent,
      _ => node,
    };
  }

  /// Return the [Element] of the given [node], or `null` if [node] is `null`,
  /// does not have an element, or the element is not a valid target for call
  /// hierarchy.
  Element? _getElementOfNode(AstNode? node) {
    if (node == null) {
      return null;
    }
    var parent = node.parent;

    // ElementLocator returns the class for default constructor calls and null
    // for constructor names.
    if (node is NamedType && parent is ConstructorName) {
      return parent.element;
    } else if (node is ConstructorName) {
      return node.element;
    } else if (node is PropertyAccess) {
      node = node.propertyName;
    }

    var element = ElementLocator.locate(node);

    // For primary constructor declarations, ElementLocator will return the
    // class on `class Fo^o() {}` but for call hierarchy we want to treat this
    // as the constructor.
    if (element is ClassElement && node is PrimaryConstructorDeclaration) {
      element = element.primaryConstructor;
    }

    // Don't consider synthetic getter/setter for a field to be executable
    // since they don't contain any executable code.
    if (element is PropertyAccessorElement && element.isOriginVariable) {
      return null;
    }

    return element;
  }

  /// Checks whether [element] is a match for [target].
  ///
  /// This is used to ensure calls are only returned for the expected target
  /// if source code has changed since the earlier request that provided
  /// [target] to the client.
  bool _isMatchingElement(Element element, CallHierarchyItem target) {
    return _getDisplayName(element) == target.displayName;
  }

  /// Returns the [SourceRange] to use for [node].
  ///
  /// The returned range covers only the name of the target and does not include
  /// the argument list.
  SourceRange _rangeForNode(AstNode node) {
    if (node is MethodInvocation) {
      return SourceRange(node.methodName.offset, node.methodName.length);
    } else if (node is InstanceCreationExpression) {
      return SourceRange(
        node.constructorName.offset,
        node.constructorName.length,
      );
    } else if (node is PropertyAccess) {
      return SourceRange(node.propertyName.offset, node.propertyName.length);
    }
    return SourceRange(node.offset, node.length);
  }

  /// Returns the [SourceRange] for [match].
  ///
  /// Usually this is the range returned from the search index, but sometimes it
  /// will be adjusted to reflect the source range that should be highlighted
  /// for this call. For example, a default constructor may be given a range
  /// covering the type name (whereas the index has a zero-width range after the
  /// type name).
  SourceRange _rangeForSearchMatch(
    SearchMatch match,
    Map<String, SomeParsedUnitResult?> parsedUnits,
  ) {
    var offset = match.sourceRange.offset;
    var length = match.sourceRange.length;
    var file = match.file;
    var result = parsedUnits.putIfAbsent(
      file,
      () => _result.session.getParsedUnit(file),
    );

    if (result is ParsedUnitResult) {
      var node = result.unit.nodeCovering(offset: offset);
      if (node != null && !node.isSynthetic) {
        var parent = node.parent;
        // Handle named constructors which have their `.` included in the
        // search index range, but we just want to highlight the name.
        if (node is SimpleIdentifier && parent is MethodInvocation) {
          offset = parent.methodName.offset;
          length = parent.methodName.length;
        } else if (length == 0) {
          // If the search index length was 0, prefer the nodes range.
          offset = node.offset;
          length = node.length;
        }
      }
    }

    return SourceRange(offset, length);
  }
}

/// Collects outbound calls from a node.
class _OutboundCallVisitor extends RecursiveAstVisitor<void> {
  final AstNode root;
  final void Function(AstNode) collect;

  _OutboundCallVisitor(this.root, this.collect);

  @override
  void visitConstructorName(ConstructorName node) {
    collect(node.name ?? node);
    super.visitConstructorName(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    collect(node.constructorName);
    super.visitDotShorthandConstructorInvocation(node);
  }

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) {
    collect(node.memberName);
    super.visitDotShorthandInvocation(node);
  }

  @override
  void visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) {
    collect(node.propertyName);
    super.visitDotShorthandPropertyAccess(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Only descend into function declarations if they are the target/root
    // function.
    if (node == root) {
      super.visitFunctionDeclaration(node);
    }
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    collect(node);
    super.visitFunctionReference(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    collect(node.methodName);
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Don't collect prefixed identifiers that are just type names. We only
    // want invocations and tear-offs.
    if (node.parent is! NamedType) {
      collect(node.identifier);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    collect(node.propertyName);
    super.visitPropertyAccess(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.element;
    if ((element is LocalFunctionElement ||
            element is TopLevelFunctionElement) &&
        !node.inDeclarationContext()) {
      collect(node);
    }
    super.visitSimpleIdentifier(node);
  }
}
