// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library glob;

import 'package:path/path.dart' as p;

import 'src/ast.dart';
import 'src/parser.dart';
import 'src/utils.dart';

/// Regular expression used to quote globs.
final _quoteRegExp = new RegExp(r'[*{[?\\}\],\-()]');

// TODO(nweiz): Add [list] and [listSync] methods.
/// A glob for matching and listing files and directories.
///
/// A glob matches an entire string as a path. Although the glob pattern uses
/// POSIX syntax, it can match against POSIX, Windows, or URL paths. The format
/// it expects paths to use is based on the `context` parameter to [new Glob];
/// it defaults to the current system's syntax.
///
/// Paths are normalized before being matched against a glob, so for example the
/// glob `foo/bar` matches the path `foo/./bar`. A relative glob can match an
/// absolute path and vice versa; globs and paths are both interpreted as
/// relative to `context.current`, which defaults to the current working
/// directory.
///
/// When used as a [Pattern], a glob will return either one or zero matches for
/// a string depending on whether the entire string matches the glob. These
/// matches don't currently have capture groups, although this may change in the
/// future.
class Glob implements Pattern {
  /// The pattern used to create this glob.
  final String pattern;

  /// The context in which paths matched against this glob are interpreted.
  final p.Context context;

  /// If true, a path matches if it matches the glob itself or is recursively
  /// contained within a directory that matches.
  final bool recursive;

  /// The parsed AST of the glob.
  final AstNode _ast;

  /// Whether [context]'s current directory is absolute.
  bool get _contextIsAbsolute {
    if (_contextIsAbsoluteCache == null) {
      _contextIsAbsoluteCache = context.isAbsolute(context.current);
    }
    return _contextIsAbsoluteCache;
  }
  bool _contextIsAbsoluteCache;

  /// Whether [pattern] could match absolute paths.
  bool get _patternCanMatchAbsolute {
    if (_patternCanMatchAbsoluteCache == null) {
      _patternCanMatchAbsoluteCache = _ast.canMatchAbsolute;
    }
    return _patternCanMatchAbsoluteCache;
  }
  bool _patternCanMatchAbsoluteCache;

  /// Whether [pattern] could match relative paths.
  bool get _patternCanMatchRelative {
    if (_patternCanMatchRelativeCache == null) {
      _patternCanMatchRelativeCache = _ast.canMatchRelative;
    }
    return _patternCanMatchRelativeCache;
  }
  bool _patternCanMatchRelativeCache;

  /// Returns [contents] with characters that are meaningful in globs
  /// backslash-escaped.
  static String quote(String contents) =>
      contents.replaceAllMapped(_quoteRegExp, (match) => '\\${match[0]}');

  /// Creates a new glob with [pattern].
  ///
  /// Paths matched against the glob are interpreted according to [context]. It
  /// defaults to the system context.
  ///
  /// If [recursive] is true, this glob will match and list not only the files
  /// and directories it explicitly lists, but anything beneath those as well.
  Glob(String pattern, {p.Context context, bool recursive: false})
      : this._(
          pattern,
          context == null ? p.context : context,
          recursive);

  // Internal constructor used to fake local variables for [context] and [ast].
  Glob._(String pattern, p.Context context, bool recursive)
      : pattern = pattern,
        context = context,
        recursive = recursive,
        _ast = new Parser(pattern + (recursive ? "{,/**}" : ""), context)
            .parse();

  /// Returns whether this glob matches [path].
  bool matches(String path) => matchAsPrefix(path) != null;

  Match matchAsPrefix(String path, [int start = 0]) {
    // Globs are like anchored RegExps in that they only match entire paths, so
    // if the match starts anywhere after the first character it can't succeed.
    if (start != 0) return null;

    if (_patternCanMatchAbsolute &&
        (_contextIsAbsolute || context.isAbsolute(path))) {
      var absolutePath = context.normalize(context.absolute(path));
      if (_ast.matches(_toPosixPath(absolutePath))) {
        return new GlobMatch(path, this);
      }
    }

    if (_patternCanMatchRelative) {
      var relativePath = context.relative(path);
      if (_ast.matches(_toPosixPath(relativePath))) {
        return new GlobMatch(path, this);
      }
    }

    return null;
  }

  /// Returns [path] converted to the POSIX format that globs match against.
  String _toPosixPath(String path) {
    if (context.style == p.Style.windows) return path.replaceAll('\\', '/');
    if (context.style == p.Style.url) return Uri.decodeFull(path);
    return path;
  }

  Iterable<Match> allMatches(String path, [int start = 0]) {
    var match = matchAsPrefix(path, start);
    return match == null ? [] : [match];
  }

  String toString() => pattern;
}
