// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path.style.windows;

import '../characters.dart' as chars;
import '../internal_style.dart';
import '../parsed_path.dart';
import '../utils.dart';

/// The style for Windows paths.
class WindowsStyle extends InternalStyle {
  WindowsStyle();

  final name = 'windows';
  final separator = '\\';
  final separators = const ['/', '\\'];

  // Deprecated properties.

  final separatorPattern = new RegExp(r'[/\\]');
  final needsSeparatorPattern = new RegExp(r'[^/\\]$');
  final rootPattern = new RegExp(r'^(\\\\[^\\]+\\[^\\/]+|[a-zA-Z]:[/\\])');
  final relativeRootPattern = new RegExp(r"^[/\\](?![/\\])");

  bool containsSeparator(String path) => path.contains('/');

  bool isSeparator(int codeUnit) =>
      codeUnit == chars.SLASH || codeUnit == chars.BACKSLASH;

  bool needsSeparator(String path) {
    if (path.isEmpty) return false;
    return !isSeparator(path.codeUnitAt(path.length - 1));
  }

  String getRoot(String path) {
    var root = _getRoot(path);
    return root == null ? getRelativeRoot(path) : root;
  }

  String getRelativeRoot(String path) {
    if (path.isEmpty) return null;
    if (!isSeparator(path.codeUnitAt(0))) return null;
    if (path.length > 1 && isSeparator(path.codeUnitAt(1))) return null;
    return path[0];
  }

  String pathFromUri(Uri uri) {
    if (uri.scheme != '' && uri.scheme != 'file') {
      throw new ArgumentError("Uri $uri must have scheme 'file:'.");
    }

    var path = uri.path;
    if (uri.host == '') {
      // Drive-letter paths look like "file:///C:/path/to/file". The
      // replaceFirst removes the extra initial slash.
      if (path.startsWith('/')) path = path.replaceFirst("/", "");
    } else {
      // Network paths look like "file://hostname/path/to/file".
      path = '\\\\${uri.host}$path';
    }
    return Uri.decodeComponent(path.replaceAll("/", "\\"));
  }

  Uri absolutePathToUri(String path) {
    var parsed = new ParsedPath.parse(path, this);
    if (parsed.root.startsWith(r'\\')) {
      // Network paths become "file://server/share/path/to/file".

      // The root is of the form "\\server\share". We want "server" to be the
      // URI host, and "share" to be the first element of the path.
      var rootParts = parsed.root.split('\\').where((part) => part != '');
      parsed.parts.insert(0, rootParts.last);

      if (parsed.hasTrailingSeparator) {
        // If the path has a trailing slash, add a single empty component so the
        // URI has a trailing slash as well.
        parsed.parts.add("");
      }

      return new Uri(scheme: 'file', host: rootParts.first,
          pathSegments: parsed.parts);
    } else {
      // Drive-letter paths become "file:///C:/path/to/file".

      // If the path is a bare root (e.g. "C:\"), [parsed.parts] will currently
      // be empty. We add an empty component so the URL constructor produces
      // "file:///C:/", with a trailing slash. We also add an empty component if
      // the URL otherwise has a trailing slash.
      if (parsed.parts.length == 0 || parsed.hasTrailingSeparator) {
        parsed.parts.add("");
      }

      // Get rid of the trailing "\" in "C:\" because the URI constructor will
      // add a separator on its own.
      parsed.parts.insert(0,
          parsed.root.replaceAll("/", "").replaceAll("\\", ""));

      return new Uri(scheme: 'file', pathSegments: parsed.parts);
    }
  }

  // A helper method for [getRoot] that doesn't handle relative roots.
  String _getRoot(String path) {
    if (path.length < 3) return null;

    // We aren't using a RegExp for this because they're slow (issue 19090). If
    // we could, we'd match against r'^(\\\\[^\\]+\\[^\\/]+|[a-zA-Z]:[/\\])'.

    // Try roots like "C:\".
    if (isAlphabetic(path.codeUnitAt(0))) {
      if (path.codeUnitAt(1) != chars.COLON) return null;
      if (!isSeparator(path.codeUnitAt(2))) return null;
      return path.substring(0, 3);
    }

    // Try roots like "\\server\share".
    if (!path.startsWith('\\\\')) return null;

    var start = 2;
    // The server is one or more non-"\" characters.
    while (start < path.length && path.codeUnitAt(start) != chars.BACKSLASH) {
      start++;
    }
    if (start == 2 || start == path.length) return null;

    // The share is one or more non-"\" characters.
    start += 1;
    if (path.codeUnitAt(start) == chars.BACKSLASH) return null;
    start += 1;
    while (start < path.length && path.codeUnitAt(start) != chars.BACKSLASH) {
      start++;
    }

    return path.substring(0, start);
  }
}