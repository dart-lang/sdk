// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library glob.ast;

import 'package:path/path.dart' as p;
import 'package:collection/collection.dart';

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

  /// Returns a new glob with all the options bubbled to the top level.
  ///
  /// In particular, this returns a glob AST with two guarantees:
  ///
  /// 1. There are no [OptionsNode]s other than the one at the top level.
  /// 2. It matches the same set of paths as [this].
  ///
  /// For example, given the glob `{foo,bar}/{click/clack}`, this would return
  /// `{foo/click,foo/clack,bar/click,bar/clack}`.
  OptionsNode flattenOptions() => new OptionsNode([new SequenceNode([this])]);

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

  OptionsNode flattenOptions() {
    if (nodes.isEmpty) return new OptionsNode([this]);

    var sequences = nodes.first.flattenOptions().options
        .map((sequence) => sequence.nodes);
    for (var node in nodes.skip(1)) {
      // Concatenate all sequences in the next options node ([nextSequences])
      // onto all previous sequences ([sequences]).
      var nextSequences = node.flattenOptions().options;
      sequences = sequences.expand((sequence) {
        return nextSequences.map((nextSequence) {
          return sequence.toList()..addAll(nextSequence.nodes);
        });
      });
    }

    return new OptionsNode(sequences.map((sequence) {
      // Combine any adjacent LiteralNodes in [sequence].
      return new SequenceNode(sequence.fold([], (combined, node) {
        if (combined.isEmpty || combined.last is! LiteralNode ||
            node is! LiteralNode) {
          return combined..add(node);
        }

        combined[combined.length - 1] =
            new LiteralNode(combined.last.text + node.text);
        return combined;
      }));
    }));
  }

  /// Splits this glob into components along its path separators.
  ///
  /// For example, given the glob `foo/*/*.dart`, this would return three globs:
  /// `foo`, `*`, and `*.dart`.
  ///
  /// Path separators within options nodes are not split. For example,
  /// `foo/{bar,baz/bang}/qux` will return three globs: `foo`, `{bar,baz/bang}`,
  /// and `qux`.
  ///
  /// [context] is used to determine what absolute roots look like for this
  /// glob.
  List<SequenceNode> split(p.Context context) {
    var componentsToReturn = [];
    var currentComponent;

    addNode(node) {
      if (currentComponent == null) currentComponent = [];
      currentComponent.add(node);
    }

    finishComponent() {
      if (currentComponent == null) return;
      componentsToReturn.add(new SequenceNode(currentComponent));
      currentComponent = null;
    }

    for (var node in nodes) {
      if (node is! LiteralNode || !node.text.contains('/')) {
        addNode(node);
        continue;
      }

      var text = node.text;
      if (context.style == p.Style.windows) text = text.replaceAll("/", "\\");
      var components = context.split(text);

      // If the first component is absolute, that means it's a separator (on
      // Windows some non-separator things are also absolute, but it's invalid
      // to have "C:" show up in the middle of a path anyway).
      if (context.isAbsolute(components.first)) {
        // If this is the first component, it's the root.
        if (componentsToReturn.isEmpty && currentComponent == null) {
          var root = components.first;
          if (context.style == p.Style.windows) {
            // Above, we switched to backslashes to make [context.split] handle
            // roots properly. That means that if there is a root, it'll still
            // have backslashes, where forward slashes are required for globs.
            // So we switch it back here.
            root = root.replaceAll("\\", "/");
          }
          addNode(new LiteralNode(root));
        }
        finishComponent();
        components = components.skip(1);
        if (components.isEmpty) continue;
      }

      // For each component except the last one, add a separate sequence to
      // [sequences] containing only that component.
      for (var component in components.take(components.length - 1)) {
        addNode(new LiteralNode(component));
        finishComponent();
      }

      // For the final component, only end its sequence (by adding a new empty
      // sequence) if it ends with a separator.
      addNode(new LiteralNode(components.last));
      if (node.text.endsWith('/')) finishComponent();
    }

    finishComponent();
    return componentsToReturn;
  }

  String _toRegExp() => nodes.map((node) => node._toRegExp()).join();

  bool operator==(Object other) => other is SequenceNode &&
      const IterableEquality().equals(nodes, other.nodes);

  int get hashCode => const IterableEquality().hash(nodes);

  String toString() => nodes.join();
}

/// A node matching zero or more non-separator characters.
class StarNode extends AstNode {
  StarNode();

  String _toRegExp() => '[^/]*';

  bool operator==(Object other) => other is StarNode;

  int get hashCode => 0;

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

  bool operator==(Object other) => other is DoubleStarNode;

  int get hashCode => 1;

  String toString() => '**';
}

/// A node matching a single non-separator character.
class AnyCharNode extends AstNode {
  AnyCharNode();

  String _toRegExp() => '[^/]';

  bool operator==(Object other) => other is AnyCharNode;

  int get hashCode => 2;

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

  OptionsNode flattenOptions() {
    if (negated || ranges.any((range) => !range.isSingleton)) {
      return super.flattenOptions();
    }

    // If a range explicitly lists a set of characters, return each character as
    // a separate expansion.
    return new OptionsNode(ranges.map((range) {
      return new SequenceNode([
        new LiteralNode(new String.fromCharCodes([range.min]))
      ]);
    }));
  }

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

  bool operator==(Object other) {
    if (other is! RangeNode) return false;
    if ((other as RangeNode).negated != negated) return false;
    return const SetEquality().equals(ranges, (other as RangeNode).ranges);
  }

  int get hashCode => (negated ? 1 : 3) * const SetEquality().hash(ranges);

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

  OptionsNode flattenOptions() => new OptionsNode(
      options.expand((option) => option.flattenOptions().options));

  String _toRegExp() =>
      '(?:${options.map((option) => option._toRegExp()).join("|")})';

  bool operator==(Object other) => other is OptionsNode && 
      const UnorderedIterableEquality().equals(options, other.options);

  int get hashCode => const UnorderedIterableEquality().hash(options);

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

  LiteralNode(this.text, [this._context]);

  String _toRegExp() => regExpQuote(text);

  bool operator==(Object other) => other is LiteralNode && other.text == text;

  int get hashCode => text.hashCode;

  String toString() => text;
}
