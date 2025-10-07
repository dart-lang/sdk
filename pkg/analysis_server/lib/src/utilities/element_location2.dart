// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';

/// Represents the location of an [Element] that exists in a chain of elements
/// from a [LibraryElement].
///
/// Elements with [Fragment]s or Elements with `null` names anywhere in the
/// chain are not representable.
class ElementLocation {
  /// The library that this element belongs to.
  final String _libraryUri;

  /// The [Element.lookupName] for this element, or the containing element if
  /// this location is a [_MemberElementLocation].
  final String _topLevelName;

  factory ElementLocation.decode(String encoded) {
    var components = encoded.split(';');
    return switch (components) {
      [String library, String topName] => ElementLocation._(library, topName),
      [String library, String topName, String memberName] =>
        _MemberElementLocation._(library, topName, memberName),
      _ => throw ArgumentError.value(
        encoded,
        'encoded',
        "Encoded string should be in the format 'libraryUri;topLevelName[;memberName]'",
      ),
    };
  }

  ElementLocation._(this._libraryUri, this._topLevelName);

  String get encoding => '$_libraryUri;$_topLevelName';

  /// Locates the [Element] represented by this [ElementLocation] in
  /// [session].
  ///
  /// Returns `null` if the [Element] cannot be located.
  Future<Element?> locateIn(AnalysisSession session) async {
    var result = await session.getLibraryByUri(_libraryUri);
    if (result is! LibraryElementResult) return null;

    return result.element.children.firstWhereOrNull(
      (child) => child.lookupName == _topLevelName,
    );
  }

  /// Gets an [ElementLocation] for this element.
  ///
  /// Returns `null` if this element is neither a top level element or a
  /// member of a top level element, or if either do not have a `lookupName`.
  static ElementLocation? forElement(Element element) {
    var library = element.library;
    if (library == null) return null;
    var libraryUri = library.uri.toString();

    if (element.enclosingElement == library) {
      var topName = element.lookupName;

      return topName != null ? ElementLocation._(libraryUri, topName) : null;
    } else if (element.enclosingElement?.enclosingElement == library) {
      var memberName = element.lookupName;
      var topName = element.enclosingElement?.lookupName;

      return topName != null && memberName != null
          ? _MemberElementLocation._(libraryUri, topName, memberName)
          : null;
    } else {
      return null;
    }
  }
}

class _MemberElementLocation extends ElementLocation {
  /// The [Element.lookupName] for this member within [_topLevelName].
  final String _memberName;

  _MemberElementLocation._(
    super.libraryUri,
    super.topLevelName,
    this._memberName,
  ) : super._();

  @override
  String get encoding => '${super.encoding};$_memberName';

  /// Locates the [Element] represented by this [_MemberElementLocation] in
  /// [session].
  ///
  /// Returns `null` if the [Element] cannot be located.
  @override
  Future<Element?> locateIn(AnalysisSession session) async {
    var topLevel = await super.locateIn(session);

    return topLevel?.children.firstWhereOrNull(
      (child) => child.lookupName == _memberName,
    );
  }
}
