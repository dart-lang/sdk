// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library glob.ast;

import 'package:path/path.dart' as p;

import 'utils.dart';

const _SEPARATOR = 0x2F; // "/"

/// A node in the abstract syntax tree for a glob.
abstract class AstNode {
  /// The cached regular expression that this AST was compiled into.
  RegExp _regExp;

  /// Whether this glob could match an absolute path.
  ///
  /// Either this or [canMatchRelative] or both will be true.
  final bool canMatchAbsolute = false;

  /// Whether this glob could match a relative path.
  ///
  /// Either this or [canMatchRelative] or both will be true.
  final bool canMatchRelative = true;

  /// Returns whether this glob matches [string].
  bool matches(String string) {
    if (_regExp == null) _regExp = new RegExp('^${_toRegExp()}\$');
    return _regExp.hasMatch(string);
  }

  /// Subclasses should override this to return a regular expression component.
  String _toRegExp();
}

/// A sequence of adjacent AST nodes.
class SequenceNode extends AstNode {
  /// The nodes in the sequence.
  final List<AstNode> nodes;

  bool get canMatchAbsolute => nodes.first.canMatchAbsolute;
  bool get canMatchRelative => nodes.first.canMatchRelative;

  SequenceNode(Iterable<AstNode> nodes)
      : nodes = nodes.toList();

  String _toRegExp() => nodes.map((node) => node._toRegExp()).join();

  String toString() => nodes.join();
}

/// A node matching zero or more non-separator characters.
class StarNode extends AstNode {
  StarNode();

  String _toRegExp() => '[^/]*';

  String toString() => '*';
}

/// A node matching zero or more characters that may be separators.
class DoubleStarNode extends AstNode {
  /// The path context for the glob.
  ///
  /// This is used to determine what absolute paths look like.
  final p.Context _context;

  DoubleStarNode(this._context);

  String _toRegExp() {
    // Double star shouldn't match paths with a leading "../", since these paths
    // wouldn't be listed with this glob. We only check for "../" at the
    // beginning since the paths are normalized before being checked against the
    // glob.
    var buffer = new StringBuffer()..write(r'(?!^(?:\.\./|');

    // A double star at the beginning of the glob also shouldn't match absolute
    // paths, since those also wouldn't be listed. Which root patterns we look
    // for depends on the style of path we're matching.
    if (_context.style == p.Style.posix) {
      buffer.write(r'/');
    } else if (_context.style == p.Style.windows) {
      buffer.write(r'//|[A-Za-z]:/');
    } else {
      assert(_context.style == p.Style.url);
      buffer.write(r'[a-zA-Z][-+.a-zA-Z\d]*://|/');
    }

    // Use `[^]` rather than `.` so that it matches newlines as well.
    buffer.write(r'))[^]*');

    return buffer.toString();
  }

  String toString() => '**';
}

/// A node matching a single non-separator character.
class AnyCharNode extends AstNode {
  AnyCharNode();

  String _toRegExp() => '[^/]';

  String toString() => '?';
}

/// A node matching a single character in a range of options.
class RangeNode extends AstNode {
  /// The ranges matched by this node.
  ///
  /// The ends of the ranges are unicode code points.
  final Set<Range> ranges;

  /// Whether this range was negated.
  final bool negated;

  RangeNode(Iterable<Range> ranges, {this.negated})
      : ranges = ranges.toSet();

  String _toRegExp() {
    var buffer = new StringBuffer();

    var containsSeparator = ranges.any((range) => range.contains(_SEPARATOR));
    if (!negated && containsSeparator) {
      // Add `(?!/)` because ranges are never allowed to match separators.
      buffer.write('(?!/)');
    }

    buffer.write('[');
    if (negated) {
      buffer.write('^');
      // If the range doesn't itself exclude separators, exclude them ourselves,
      // since ranges are never allowed to match them.
      if (!containsSeparator) buffer.write('/');
    }

    for (var range in ranges) {
      var start = new String.fromCharCodes([range.min]);
      buffer.write(regExpQuote(start));
      if (range.isSingleton) continue;
      buffer.write('-');
      buffer.write(regExpQuote(new String.fromCharCodes([range.max])));
    }

    buffer.write(']');
    return buffer.toString();
  }

  String toString() {
    var buffer = new StringBuffer()..write('[');
    for (var range in ranges) {
      buffer.writeCharCode(range.min);
      if (range.isSingleton) continue;
      buffer.write('-');
      buffer.writeCharCode(range.max);
    }
    buffer.write(']');
    return buffer.toString();
  }
}

/// A node that matches one of several options.
class OptionsNode extends AstNode {
  /// The options to match.
  final List<SequenceNode> options;

  bool get canMatchAbsolute => options.any((node) => node.canMatchAbsolute);
  bool get canMatchRelative => options.any((node) => node.canMatchRelative);

  OptionsNode(Iterable<SequenceNode> options)
      : options = options.toList();

  String _toRegExp() =>
      '(?:${options.map((option) => option._toRegExp()).join("|")})';

  String toString() => '{${options.join(',')}}';
}

/// A node that matches a literal string.
class LiteralNode extends AstNode {
  /// The string to match.
  final String text;

  /// The path context for the glob.
  ///
  /// This is used to determine whether this could match an absolute path.
  final p.Context _context;

  bool get canMatchAbsolute {
    var nativeText = _context.style == p.Style.windows ?
        text.replaceAll('/', '\\') : text;
    return _context.isAbsolute(nativeText);
  }

  bool get canMatchRelative => !canMatchAbsolute;

  LiteralNode(this.text, this._context);

  String _toRegExp() => regExpQuote(text);

  String toString() => text;
}
