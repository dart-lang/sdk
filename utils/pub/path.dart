// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A comprehensive, cross-platform path manipulation library.
library path;

import 'dart:io' as io;

/// An internal builder for the current OS so we can provide a straight
/// functional interface and not require users to create one.
final _builder = new Builder();

/// Gets the path to the current working directory.
String get current => new io.Directory.current().path;

/// Gets the path separator for the current platform. On Mac and Linux, this
/// is `/`. On Windows, it's `\`.
String get separator => _builder.separator;

/// Converts [path] to an absolute path by resolving it relative to the current
/// working directory. If [path] is already an absolute path, just returns it.
///
///     path.absolute('foo/bar.txt'); // -> /your/current/dir/foo/bar.txt
String absolute(String path) => join(current, path);

/// Gets the file extension of [path]; the portion after the last `.` in the
/// [basename] of the path.
///
///     path.extension('path/to/foo.dart');    // -> '.dart'
///     path.extension('path/to/foo');         // -> ''
///     path.extension('path.to/foo');         // -> ''
///     path.extension('path/to/foo.dart.js'); // -> '.js'
///
/// If the file name starts with a `.`, then it is not considered an extension:
///
///     path.extension('~/.bashrc'); // -> ''
String extension(String path) => _builder.extension(path);

/// Gets the part of [path] after the last separator on the current platform.
///
///     path.filename('path/to/foo.dart'); // -> 'foo.dart'
///     path.filename('path/to');          // -> 'to'
String filename(String path) => _builder.filename(path);

/// Gets the part of [path] after the last separator on the current platform,
/// and without any trailing file extension.
///
///     path.filenameWithoutExtension('path/to/foo.dart'); // -> 'foo'
String filenameWithoutExtension(String path) =>
    _builder.filenameWithoutExtension(path);

/// Returns `true` if [path] is an absolute path and `false` if it is a
/// relative path. On Mac and Unix systems, relative paths start with a `/`
/// (forward slash). On Windows, an absolute path starts with `\\`, or a drive
/// letter followed by `:/` or `:\`.
bool isAbsolute(String path) => _builder.isAbsolute(path);

/// Returns `true` if [path] is a relative path and `false` if it is absolute.
/// On Mac and Unix systems, relative paths start with a `/` (forward slash).
/// On Windows, an absolute path starts with `\\`, or a drive letter followed
/// by `:/` or `:\`.
bool isRelative(String path) => _builder.isRelative(path);

/// Joins the given path parts into a single path using the current platform's
/// [separator]. Example:
///
///     path.join('path', 'to', 'foo'); // -> 'path/to/foo'
///
/// If any part ends in a path separator, then a redundant separator will not
/// be added:
///
///     path.join('path/', 'to', 'foo'); // -> 'path/to/foo
///
/// If a part is an absolute path, then anything before that will be ignored:
///
///     path.join('path', '/to', 'foo'); // -> '/to/foo'
///
String join(String part1, [String part2, String part3, String part4,
            String part5, String part6, String part7, String part8]) {
  if (!?part2) return _builder.join(part1);
  if (!?part3) return _builder.join(part1, part2);
  if (!?part4) return _builder.join(part1, part2, part3);
  if (!?part5) return _builder.join(part1, part2, part3, part4);
  if (!?part6) return _builder.join(part1, part2, part3, part4, part5);
  if (!?part7) return _builder.join(part1, part2, part3, part4, part5, part6);
  if (!?part8) return _builder.join(part1, part2, part3, part4, part5, part6,
                                    part7);
  return _builder.join(part1, part2, part3, part4, part5, part6, part7, part8);
}

/// Normalizes [path], simplifying it by handling `..`, and `.`, and
/// removing redundant path separators whenever possible.
///
///     path.normalize('path/./to/..//file.text'); // -> 'path/file.txt'
String normalize(String path) => _builder.normalize(path);

/// Converts [path] to an equivalent relative path from the current directory.
///
///     // Given current directory is /root/path:
///     path.relative('/root/path/a/b.dart'); // -> 'a/b.dart'
///     path.relative('/root/other.dart'); // -> '../other.dart'
String relative(String path) => _builder.relative(path);

/// Removes a trailing extension from the last part of [path].
///
///     withoutExtension('path/to/foo.dart'); // -> 'path/to/foo'
String withoutExtension(String path) => _builder.withoutExtension(path);

/// An instantiable class for manipulating paths. Unlike the top-level
/// functions, this lets you explicitly select what platform the paths will use.
class Builder {
  /// Creates a new path builder for the given style and root directory.
  ///
  /// If [style] is omitted, it uses the host operating system's path style. If
  /// [root] is omitted, it defaults to the current working directory.
  factory Builder({Style style, String root}) {
    if (style == null) {
      if (io.Platform.operatingSystem == 'windows') {
        style = Style.windows;
      } else {
        style = Style.posix;
      }
    }

    if (root == null) root = new io.Directory.current().path;

    return new Builder._(style, root);
  }

  Builder._(this.style, this.root);

  /// The style of path that this builder works with.
  final Style style;

  /// The root directory that relative paths will be relative to.
  final String root;

  /// Gets the path separator for the builder's [style]. On Mac and Linux,
  /// this is `/`. On Windows, it's `\`.
  String get separator => style.separator;

  /// Gets the file extension of [path]; the portion after the last `.` in the
  /// [basename] of the path.
  ///
  ///     builder.extension('path/to/foo.dart'); // -> '.dart'
  ///     builder.extension('path/to/foo'); // -> ''
  ///     builder.extension('path.to/foo'); // -> ''
  ///     builder.extension('path/to/foo.dart.js'); // -> '.js'
  ///
  /// If the file name starts with a `.`, then it is not considered an
  /// extension:
  ///
  ///     builder.extension('~/.bashrc'); // -> ''
  String extension(String path) => _parse(path).extension;

  /// Gets the part of [path] after the last separator on the builder's
  /// platform.
  ///
  ///     builder.filename('path/to/foo.dart'); // -> 'foo.dart'
  ///     builder.filename('path/to');          // -> 'to'
  String filename(String path) => _parse(path).filename;

  /// Gets the part of [path] after the last separator on the builder's
  /// platform, and without any trailing file extension.
  ///
  ///     builder.filenameWithoutExtension('path/to/foo.dart'); // -> 'foo'
  String filenameWithoutExtension(String path) =>
      _parse(path).filenameWithoutExtension;

  /// Returns `true` if [path] is an absolute path and `false` if it is a
  /// relative path. On Mac and Unix systems, relative paths start with a `/`
  /// (forward slash). On Windows, an absolute path starts with `\\`, or a drive
  /// letter followed by `:/` or `:\`.
  bool isAbsolute(String path) => _parse(path).isAbsolute;

  /// Returns `true` if [path] is a relative path and `false` if it is absolute.
  /// On Mac and Unix systems, relative paths start with a `/` (forward slash).
  /// On Windows, an absolute path starts with `\\`, or a drive letter followed
  /// by `:/` or `:\`.
  bool isRelative(String path) => !isAbsolute(path);

  /// Joins the given path parts into a single path. Example:
  ///
  ///     builder.join('path', 'to', 'foo'); // -> 'path/to/foo'
  ///
  /// If any part ends in a path separator, then a redundant separator will not
  /// be added:
  ///
  ///     builder.join('path/', 'to', 'foo'); // -> 'path/to/foo
  ///
  /// If a part is an absolute path, then anything before that will be ignored:
  ///
  ///     builder.join('path', '/to', 'foo'); // -> '/to/foo'
  ///
  String join(String part1, [String part2, String part3, String part4,
              String part5, String part6, String part7, String part8]) {
    var buffer = new StringBuffer();
    var needsSeparator = false;

    addPart(condition, part) {
      if (!condition) return;

      if (this.isAbsolute(part)) {
        // An absolute path discards everything before it.
        buffer.clear();
        buffer.add(part);
      } else {
        if (part.length > 0 && style.separatorPattern.hasMatch(part[0])) {
          // The part starts with a separator, so we don't need to add one.
        } else if (needsSeparator) {
          buffer.add(separator);
        }

        buffer.add(part);
      }

      // Unless this part ends with a separator, we'll need to add one before
      // the next part.
      needsSeparator = part.length > 0 &&
          !style.separatorPattern.hasMatch(part[part.length - 1]);
    }

    addPart(true, part1);
    addPart(?part2, part2);
    addPart(?part3, part3);
    addPart(?part4, part4);
    addPart(?part5, part5);
    addPart(?part6, part6);
    addPart(?part7, part7);
    addPart(?part8, part8);

    return buffer.toString();
  }

  /// Normalizes [path], simplifying it by handling `..`, and `.`, and
  /// removing redundant path separators whenever possible.
  ///
  ///     builder.normalize('path/./to/..//file.text'); // -> 'path/file.txt'
  String normalize(String path) {
    if (path == '') return path;

    var parsed = _parse(path);
    parsed.normalize();
    return parsed.toString();
  }

  /// Creates a new path by appending the given path parts to the [root].
  /// Equivalent to [join()] with [root] as the first argument. Example:
  ///
  ///     var builder = new Builder(root: 'root');
  ///     builder.join('path', 'to', 'foo'); // -> 'root/path/to/foo'
  String resolve(String part1, [String part2, String part3, String part4,
              String part5, String part6, String part7]) {
    if (!?part2) return join(root, part1);
    if (!?part3) return join(root, part1, part2);
    if (!?part4) return join(root, part1, part2, part3);
    if (!?part5) return join(root, part1, part2, part3, part4);
    if (!?part6) return join(root, part1, part2, part3, part4, part5);
    if (!?part7) return join(root, part1, part2, part3, part4, part5, part6);
    return join(root, part1, part2, part3, part4, part5, part6, part7);
  }

  /// Converts [path] to an equivalent relative path starting at [root].
  ///
  ///     var builder = new Builder(root: '/root/path');
  ///     builder.relative('/root/path/a/b.dart'); // -> 'a/b.dart'
  ///     builder.relative('/root/other.dart'); // -> '../other.dart'
  String relative(String path) {
    // If the base path is relative, resolve it relative to the current
    // directory.
    var base = root;
    if (this.isRelative(base)) base = absolute(base);

    // If the given path is relative, resolve it relative to the base.
    path = this.join(base, path);

    var baseParsed = _parse(base)..normalize();
    var pathParsed = _parse(path)..normalize();

    // If the root prefixes don't match (for example, different drive letters
    // on Windows), then there is no relative path, so just return the absolute
    // one.
    if (baseParsed.root != pathParsed.root) return pathParsed.toString();

    // Strip off their common prefix.
    while (baseParsed.parts.length > 0 && pathParsed.parts.length > 0) {
      if (baseParsed.parts[0] != pathParsed.parts[0]) break;
      baseParsed.parts.removeAt(0);
      baseParsed.separators.removeAt(0);
      pathParsed.parts.removeAt(0);
      pathParsed.separators.removeAt(0);
    }

    // If there are any directories left in the root path, we need to walk up
    // out of them.
    pathParsed.parts.insertRange(0, baseParsed.parts.length, '..');
    pathParsed.separators.insertRange(0, baseParsed.parts.length,
        style.separator);

    // Corner case: the paths completely collapsed.
    if (pathParsed.parts.length == 0) return '.';

    // Make it relative.
    pathParsed.root = '';
    pathParsed.removeTrailingSeparator();

    return pathParsed.toString();
  }

  /// Removes a trailing extension from the last part of [path].
  ///
  ///     builder.withoutExtension('path/to/foo.dart'); // -> 'path/to/foo'
  String withoutExtension(String path) {
    var lastSeparator = path.lastIndexOf(separator);
    var lastDot = path.lastIndexOf('.');

    // Ignore '.' in anything but the last component.
    if (lastSeparator != -1 && lastDot <= lastSeparator + 1) lastDot = -1;

    if (lastDot <= 0) return path;
    return path.substring(0, lastDot);
  }

  _ParsedPath _parse(String path) {
    var before = path;

    // Remove the root prefix, if any.
    var root = style.getRoot(path);
    if (root != null) path = path.substring(root.length);

    // Split the parts on path separators.
    var parts = [];
    var separators = [];
    var start = 0;
    for (var match in style.separatorPattern.allMatches(path)) {
      parts.add(path.substring(start, match.start));
      separators.add(match[0]);
      start = match.end;
    }

    // Add the final part, if any.
    if (start < path.length) {
      parts.add(path.substring(start));
      separators.add('');
    }

    // Separate out the file extension.
    var extension = '';
    if (parts.length > 0) {
      var file = parts.last;
      if (file != '..') {
        var lastDot = file.lastIndexOf('.');

        // If there is a dot (and it's not the first character, like '.bashrc').
        if (lastDot > 0) {
          parts[parts.length - 1] = file.substring(0, lastDot);
          extension = file.substring(lastDot);
        }
      }
    }

    return new _ParsedPath(style, root, parts, separators, extension);
  }
}

/// An enum type describing a "flavor" of path.
class Style {
  /// POSIX-style paths use "/" (forward slash) as separators. Absolute paths
  /// start with "/". Used by UNIX, Linux, Mac OS X, and others.
  static final posix = new Style._('posix', '/', '/', '/');

  /// Windows paths use "\" (backslash) as separators. Absolute paths start with
  /// a drive letter followed by a colon (example, "C:") or two backslashes
  /// ("\\") for UNC paths.
  static final windows = new Style._('windows', '\\', r'[/\\]',
      r'\\\\|[a-zA-Z]:[/\\]');

  Style._(this.name, this.separator, String separatorPattern, String rootPattern)
    : separatorPattern = new RegExp(separatorPattern),
      _rootPattern = new RegExp('^$rootPattern');

  /// The name of this path style. Will be "posix" or "windows".
  final String name;

  /// The path separator for this style. On POSIX, this is `/`. On Windows,
  /// it's `\`.
  final String separator;

  /// The [Pattern] that can be used to match a separator for a path in this
  /// style. Windows allows both "/" and "\" as path separators even though
  /// "\" is the canonical one.
  final Pattern separatorPattern;

  /// The [Pattern] that can be used to match the root prefix of an absolute
  /// path in this style.
  final Pattern _rootPattern;

  /// Gets the root prefix of [path] if path is absolute. If [path] is relative,
  /// returns `null`.
  String getRoot(String path) {
    var match = _rootPattern.firstMatch(path);
    if (match == null) return null;
    return match[0];
  }

  String toString() => name;
}

// TODO(rnystrom): Make this public?
class _ParsedPath {
  /// The [Style] that was used to parse this path.
  Style style;

  /// The absolute root portion of the path, or `null` if the path is relative.
  /// On POSIX systems, this will be `null` or "/". On Windows, it can be
  /// `null`, "//" for a UNC path, or something like "C:\" for paths with drive
  /// letters.
  String root;

  /// The path-separated parts of the path. All but the last will be
  /// directories. The last could be a directory, or could be the file name
  /// without its extension.
  List<String> parts;

  /// The path separators following each part. The last one will be an empty
  /// string unless the path ends with a trailing separator.
  List<String> separators;

  /// The file's extension, or "" if it doesn't have one.
  String extension;

  /// `true` if the path ends with a trailing separator.
  bool get hasTrailingSeparator {
    if (separators.length == 0) return false;
    return separators[separators.length - 1] != '';
  }

  /// `true` if this is an absolute path.
  bool get isAbsolute => root != null;

  _ParsedPath(this.style, this.root, this.parts, this.separators,
              this.extension);

  String get filename {
    if (parts.length == 0) return extension;
    if (hasTrailingSeparator) return '';
    return '${parts.last}$extension';
  }

  String get filenameWithoutExtension {
    if (parts.length == 0) return '';
    if (hasTrailingSeparator) return '';
    return parts.last;
  }

  void removeTrailingSeparator() {
    if (separators.length > 0) {
      separators[separators.length - 1] = '';
    }
  }

  void normalize() {
    // Handle '.', '..', and empty parts.
    var leadingDoubles = 0;
    var newParts = [];
    for (var part in parts) {
      if (part == '.' || part == '') {
        // Do nothing. Ignore it.
      } else if (part == '..') {
        // Pop the last part off.
        if (newParts.length > 0) {
          newParts.removeLast();
        } else {
          // Backed out past the beginning, so preserve the "..".
          leadingDoubles++;
        }
      } else {
        newParts.add(part);
      }
    }

    // A relative path can back out from the start directory.
    if (!isAbsolute) {
      newParts.insertRange(0, leadingDoubles, '..');
    }

    // If we collapsed down to nothing, do ".".
    if (newParts.length == 0 && !isAbsolute) {
      newParts.add('.');
    }

    // Canonicalize separators.
    var newSeparators = [];
    newSeparators.insertRange(0, newParts.length, style.separator);

    parts = newParts;
    separators = newSeparators;

    removeTrailingSeparator();
  }

  String toString() {
    var builder = new StringBuffer();
    if (root != null) builder.add(root);
    for (var i = 0; i < parts.length; i++) {
      builder.add(parts[i]);
      if (extension != null && i == parts.length - 1) builder.add(extension);
      builder.add(separators[i]);
    }

    return builder.toString();
  }
}
