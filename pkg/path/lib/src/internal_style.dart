// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path.internal_style;

import 'context.dart';
import 'style.dart';

/// The internal interface for the [Style] type.
///
/// Users should be able to pass around instances of [Style] like an enum, but
/// the members that [Context] uses should be hidden from them. Those members
/// are defined on this class instead.
abstract class InternalStyle extends Style {
  /// The path separator for this style. On POSIX, this is `/`. On Windows,
  /// it's `\`.
  String get separator;

  /// The [Pattern] that can be used to match a separator for a path in this
  /// style. Windows allows both "/" and "\" as path separators even though "\"
  /// is the canonical one.
  Pattern get separatorPattern;

  /// The [Pattern] that matches path components that need a separator after
  /// them.
  ///
  /// Windows and POSIX styles just need separators when the previous component
  /// doesn't already end in a separator, but the URL always needs to place a
  /// separator between the root and the first component, even if the root
  /// already ends in a separator character. For example, to join "file://" and
  /// "usr", an additional "/" is needed (making "file:///usr").
  Pattern get needsSeparatorPattern;

  /// The [Pattern] that can be used to match the root prefix of an absolute
  /// path in this style.
  Pattern get rootPattern;

  /// The [Pattern] that can be used to match the root prefix of a root-relative
  /// path in this style.
  ///
  /// This can be null to indicate that this style doesn't support root-relative
  /// paths.
  final Pattern relativeRootPattern = null;

  /// Gets the root prefix of [path] if path is absolute. If [path] is relative,
  /// returns `null`.
  String getRoot(String path) {
    // TODO(rnystrom): Use firstMatch() when #7080 is fixed.
    var matches = rootPattern.allMatches(path);
    if (matches.isNotEmpty) return matches.first[0];
    return getRelativeRoot(path);
  }

  /// Gets the root prefix of [path] if it's root-relative.
  ///
  /// If [path] is relative or absolute and not root-relative, returns `null`.
  String getRelativeRoot(String path) {
    if (relativeRootPattern == null) return null;
    // TODO(rnystrom): Use firstMatch() when #7080 is fixed.
    var matches = relativeRootPattern.allMatches(path);
    if (matches.isEmpty) return null;
    return matches.first[0];
  }

  /// Returns the path represented by [uri] in this style.
  String pathFromUri(Uri uri);

  /// Returns the URI that represents the relative path made of [parts].
  Uri relativePathToUri(String path) =>
      new Uri(pathSegments: context.split(path));

  /// Returns the URI that represents [path], which is assumed to be absolute.
  Uri absolutePathToUri(String path);
}
