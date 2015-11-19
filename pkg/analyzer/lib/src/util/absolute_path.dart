// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.util.absolute_path;

/// The class for manipulating absolute paths.
class AbsolutePathContext {
  final String separator;

  int _separatorChar;

  AbsolutePathContext(this.separator) {
    if (separator.length != 1) {
      throw new ArgumentError.value(
          separator, 'separator', 'must be exactly one character long');
    }
    _separatorChar = separator.codeUnitAt(0);
  }

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
    int parentLength = parent.length;
    int childLength = child.length;
    if (parentLength >= childLength) {
      return false;
    }
    if (child.codeUnitAt(parentLength) != _separatorChar) {
      return false;
    }
    return _startsWithUnsafe(child, parent);
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
  ///     context.relative('/root/path', '/root/path/a/b.dart'); // -> 'a/b.dart'
  ///     context.relative('/root/path', '/root/other.dart');    // -> null
  String suffix(String parent, String child) {
    String parentPrefix = parent + separator;
    if (child.startsWith(parentPrefix)) {
      return child.substring(parentPrefix.length);
    }
    return null;
  }

  /// Return `true` if [str] starts with the given [prefix].
  ///
  /// The check is done from the end of [prefix], because absolute paths
  /// usually have the same prefix, e.g. the user's home directory.
  static bool _startsWithUnsafe(String str, String prefix) {
    int len = prefix.length;
    for (int i = len - 1; i >= 0; i--) {
      if (str.codeUnitAt(i) != prefix.codeUnitAt(i)) {
        return false;
      }
    }
    return true;
  }
}
