// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path.style.windows;

import '../parsed_path.dart';
import '../style.dart';

/// The style for Windows paths.
class WindowsStyle extends Style {
  WindowsStyle();

  final name = 'windows';
  final separator = '\\';
  final separatorPattern = new RegExp(r'[/\\]');
  final needsSeparatorPattern = new RegExp(r'[^/\\]$');
  final rootPattern = new RegExp(r'^(\\\\[^\\]+\\[^\\/]+|[a-zA-Z]:[/\\])');
  final relativeRootPattern = new RegExp(r"^[/\\](?![/\\])");

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
      parsed.parts.insert(0, parsed.root.replaceAll(separatorPattern, ""));

      return new Uri(scheme: 'file', pathSegments: parsed.parts);
    }
  }
}