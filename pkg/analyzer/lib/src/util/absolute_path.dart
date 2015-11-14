// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.util.absolute_path;

/// The class for manipulating absolute paths.
class AbsolutePathContext {
  final String separator;

  AbsolutePathContext(this.separator);

  /// Append the given relative [suffix] to the given absolute [parent].
  ///
  ///     context.append('/path/to', 'foo'); // -> '/path/to/foo'
  ///
  /// The given [suffix] cannot be an absolute path or use `..`.
  String append(String parent, String suffix) {
    return '$parent$separator$suffix';
  }

  /// Return the part of the absolute [path] after the last separator on the
  /// context's platform.
  ///
  ///     context.basename('/path/to/foo.dart'); // -> 'foo.dart'
  ///     context.basename('/path/to');          // -> 'to'
  ///     context.basename('/path');             // -> 'path'
  ///     context.basename('/');                 // -> ''
  String basename(String path) {
    int index = path.lastIndexOf(separator);
    return path.substring(index + 1);
  }

  /// Return the part of the absolute [path] before the last separator.
  ///
  ///     context.dirname('/path/to/foo.dart'); // -> '/path/to'
  ///     context.dirname('/path/to');          // -> '/path'
  ///     context.dirname(r'/path');            // -> '/'
  ///     context.dirname(r'/');                // -> '/'
  ///     context.dirname(r'C:\path');          // -> 'C:\'
  ///     context.dirname(r'C:\');              // -> 'C:\'
  String dirname(String path) {
    int firstIndex = path.indexOf(separator);
    int lastIndex = path.lastIndexOf(separator);
    return lastIndex == firstIndex
        ? path.substring(0, firstIndex + 1)
        : path.substring(0, lastIndex);
  }

  /// Return `true` if [child] is a path beneath [parent], and `false`
  /// otherwise. Both the [child] and [parent] paths must be absolute paths.
  ///
  ///     context.isWithin('/root/path', '/root/path/a'); // -> true
  ///     context.isWithin('/root/path', '/root/other');  // -> false
  ///     context.isWithin('/root/path', '/root/path');   // -> false
  bool isWithin(String parent, String child) {
    return child.startsWith(parent + separator);
  }

  /// Split [path] into its components using [separator].
  ///
  ///     context.split('/path/to/foo'); // -> ['', 'path', 'to', 'foo']
  List<String> split(String path) {
    return path.split(separator);
  }

  /// If the given [child] is within the given [parent], then return the
  /// relative path from [parent] to [child]. Otherwise return `null`. Both
  /// the [child] and [parent] paths must be absolute paths.
  ///
  ///     context.relative('/root/path/a/b.dart', '/root/path'); // -> 'a/b.dart'
  ///     context.relative('/root/other.dart', '/root/path');    // -> null
  String suffix(String child, String parent) {
    String parentPrefix = parent + separator;
    if (child.startsWith(parentPrefix)) {
      return child.substring(parentPrefix.length);
    }
    return null;
  }
}
