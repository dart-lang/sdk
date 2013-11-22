// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path.style;

import 'context.dart';
import 'style/posix.dart';
import 'style/url.dart';
import 'style/windows.dart';

/// An enum type describing a "flavor" of path.
abstract class Style {
  /// POSIX-style paths use "/" (forward slash) as separators. Absolute paths
  /// start with "/". Used by UNIX, Linux, Mac OS X, and others.
  static final posix = new PosixStyle();

  /// Windows paths use "\" (backslash) as separators. Absolute paths start with
  /// a drive letter followed by a colon (example, "C:") or two backslashes
  /// ("\\") for UNC paths.
  // TODO(rnystrom): The UNC root prefix should include the drive name too, not
  // just the "\\".
  static final windows = new WindowsStyle();

  /// URLs aren't filesystem paths, but they're supported to make it easier to
  /// manipulate URL paths in the browser.
  ///
  /// URLs use "/" (forward slash) as separators. Absolute paths either start
  /// with a protocol and optional hostname (e.g. `http://dartlang.org`,
  /// `file://`) or with "/".
  static final url = new UrlStyle();

  /// The style of the host platform.
  ///
  /// When running on the command line, this will be [windows] or [posix] based
  /// on the host operating system. On a browser, this will be [url].
  static final platform = _getPlatformStyle();

  /// Gets the type of the host platform.
  static Style _getPlatformStyle() {
    // If we're running a Dart file in the browser from a `file:` URI,
    // [Uri.base] will point to a file. If we're running on the standalone,
    // it will point to a directory. We can use that fact to determine which
    // style to use.
    if (Uri.base.scheme != 'file') return Style.url;
    if (!Uri.base.path.endsWith('/')) return Style.url;
    if (new Uri(path: 'a/b').toFilePath() == 'a\\b') return Style.windows;
    return Style.posix;
  }

  /// The name of this path style. Will be "posix" or "windows".
  String get name;

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

  /// A [Context] that uses this style.
  Context get context => new Context(style: this);

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

  String toString() => name;
}
