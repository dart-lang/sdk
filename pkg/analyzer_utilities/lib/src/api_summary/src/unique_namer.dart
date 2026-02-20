// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_utilities/src/api_summary/src/extensions.dart';

/// Object that will have a unique string representation within the context of a
/// given [UniqueNamer] instance.
///
/// If two or more [UniqueName] objects are constructed with reference to the
/// same [UniqueNamer], and they have the same [_nameHint], then all such
/// objects' [toString] methods will append a unique suffix of the form
/// `@INTEGER`, so that the resulting strings are unique.
class UniqueName {
  /// The name that will be returned by [toString] if no disambiguation is
  /// needed.
  final String _nameHint;

  /// If not `Null`, the integer that [toString] will use to disambiguate this
  /// [UniqueName] from other ones with the same [_nameHint].
  int? _disambiguator;

  UniqueName(UniqueNamer uniqueNamer, this._nameHint) {
    // The uniqueness guarantee depends on `_nameHint` not containing an `@`.
    assert(!_nameHint.contains('@'));
    var conflicts = uniqueNamer._conflicts[_nameHint] ??= [];
    if (conflicts.length == 1) {
      conflicts[0]._disambiguator = 1;
    }
    conflicts.add(this);
    if (conflicts.length > 1) {
      _disambiguator = conflicts.length;
    }
  }

  @override
  String toString() => [
    _nameHint,
    if (_disambiguator case var disambiguator?) '@$disambiguator',
  ].join();
}

/// Manager of unique names for elements.
class UniqueNamer {
  final _names = <Element, UniqueName>{};
  final _conflicts = <String, List<UniqueName>>{};

  /// Returns a [UniqueName] object whose [toString] method will produce a
  /// unique name for [element].
  UniqueName name(Element element) =>
      _names[element] ??= UniqueName(this, element.apiName);
}
