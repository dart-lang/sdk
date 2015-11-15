// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.util.glob;

/**
 * A pattern that matches against filesystem path-like strings with wildcards.
 *
 * The pattern matches strings as follows:
 *   * The pattern must use `/` as the path separator.
 *   * The whole string must match, not a substring.
 *   * Any non wildcard is matched as a literal.
 *   * '*' matches one or more characters except '/'.
 *   * '?' matches exactly one character except '/'.
 *   * '**' matches one or more characters including '/'.
 */
class Glob {
  /**
   * The special characters are: \ ^ $ . | + [ ] ( ) { }
   * as defined here: http://ecma-international.org/ecma-262/5.1/#sec-15.10
   */
  static final RegExp _specialChars =
      new RegExp(r'([\\\^\$\.\|\+\[\]\(\)\{\}])');

  /**
   * The path separator used to separate components in file paths.
   */
  final String _separator;

  final String pattern;
  final RegExp _regex;

  Glob(this._separator, String pattern)
      : pattern = pattern,
        _regex = _regexpFromGlobPattern(pattern);

  @override
  int get hashCode => pattern.hashCode;

  bool operator ==(other) => other is Glob && pattern == other.pattern;

  /**
   * Return `true` if the given [path] matches this glob.
   * The given [path] must use the same [_separator] as the glob.
   */
  bool matches(String path) {
    String posixPath = _toPosixPath(path);
    return _regex.matchAsPrefix(posixPath) != null;
  }

  @override
  String toString() => pattern;

  /**
   * Return the Posix version of the given [path].
   */
  String _toPosixPath(String path) {
    if (_separator == '/') {
      return path;
    }
    return path.replaceAll(_separator, '/');
  }

  static RegExp _regexpFromGlobPattern(String pattern) {
    StringBuffer sb = new StringBuffer();
    sb.write('^');
    List<String> chars = pattern.split('');
    for (int i = 0; i < chars.length; i++) {
      String c = chars[i];
      if (_specialChars.hasMatch(c)) {
        sb.write(r'\');
        sb.write(c);
      } else if (c == '*') {
        if (i + 1 < chars.length && chars[i + 1] == '*') {
          sb.write('.*');
          i++;
        } else {
          sb.write('[^/]*');
        }
      } else if (c == '?') {
        sb.write('[^/]');
      } else {
        sb.write(c);
      }
    }
    sb.write(r'$');
    return new RegExp(sb.toString(), caseSensitive: false);
  }
}
