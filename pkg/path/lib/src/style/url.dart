// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path.style.url;

import '../characters.dart' as chars;
import '../internal_style.dart';
import '../utils.dart';

/// The style for URL paths.
class UrlStyle extends InternalStyle {
  UrlStyle();

  final name = 'url';
  final separator = '/';
  final separators = const ['/'];

  // Deprecated properties.

  final separatorPattern = new RegExp(r'/');
  final needsSeparatorPattern = new RegExp(
      r"(^[a-zA-Z][-+.a-zA-Z\d]*://|[^/])$");
  final rootPattern = new RegExp(r"[a-zA-Z][-+.a-zA-Z\d]*://[^/]*");
  final relativeRootPattern = new RegExp(r"^/");

  bool containsSeparator(String path) => path.contains('/');

  bool isSeparator(int codeUnit) => codeUnit == chars.SLASH;

  bool needsSeparator(String path) {
    if (path.isEmpty) return false;

    // A URL that doesn't end in "/" always needs a separator.
    if (!isSeparator(path.codeUnitAt(path.length - 1))) return true;

    // A URI that's just "scheme://" needs an extra separator, despite ending
    // with "/".
    var root = _getRoot(path);
    return root != null && root.endsWith('://');
  }

  String getRoot(String path) {
    var root = _getRoot(path);
    return root == null ? getRelativeRoot(path) : root;
  }

  String getRelativeRoot(String path) {
    if (path.isEmpty) return null;
    return isSeparator(path.codeUnitAt(0)) ? "/" : null;
  }

  String pathFromUri(Uri uri) => uri.toString();

  Uri relativePathToUri(String path) => Uri.parse(path);
  Uri absolutePathToUri(String path) => Uri.parse(path);

  // A helper method for [getRoot] that doesn't handle relative roots.
  String _getRoot(String path) {
    if (path.isEmpty) return null;

    // We aren't using a RegExp for this because they're slow (issue 19090). If
    // we could, we'd match against r"[a-zA-Z][-+.a-zA-Z\d]*://[^/]*".

    if (!isAlphabetic(path.codeUnitAt(0))) return null;
    var start = 1;
    for (; start < path.length; start++) {
      var char = path.codeUnitAt(start);
      if (isAlphabetic(char)) continue;
      if (isNumeric(char)) continue;
      if (char == chars.MINUS || char == chars.PLUS || char == chars.PERIOD) {
        continue;
      }

      break;
    }

    if (start + 3 > path.length) return null;
    if (path.substring(start, start + 3) != '://') return null;
    start += 3;

    // A URL root can end with a non-"/" prefix.
    while (start < path.length && !isSeparator(path.codeUnitAt(start))) {
      start++;
    }
    return path.substring(0, start);
  }
}
