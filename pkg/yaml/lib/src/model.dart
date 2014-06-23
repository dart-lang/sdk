// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains the node classes for the internal representations of YAML
/// documents. These nodes are used for both the serialization tree and the
/// representation graph.
library yaml.model;

import 'package:source_maps/source_maps.dart';

import 'equality.dart';
import 'parser.dart';
import 'visitor.dart';
import 'yaml_exception.dart';

/// The prefix for tag types defined by the YAML spec.
const _YAML_URI_PREFIX = "tag:yaml.org,2002:";

/// A tag that indicates the type of a YAML node.
class Tag {
  /// The name of the tag, either a URI or a local tag beginning with "!".
  final String name;

  /// The kind of the tag.
  final TagKind kind;

  /// Returns the standard YAML tag URI for [type].
  static String yaml(String type) => "tag:yaml.org,2002:$type";

  const Tag(this.name, this.kind);

  const Tag.scalar(String name)
      : this(name, TagKind.SCALAR);

  const Tag.sequence(String name)
      : this(name, TagKind.SEQUENCE);

  const Tag.mapping(String name)
      : this(name, TagKind.MAPPING);

  /// Two tags are equal if their URIs are equal.
  operator ==(other) {
    if (other is! Tag) return false;
    return name == other.name;
  }

  String toString() {
    if (name.startsWith(_YAML_URI_PREFIX)) {
      return '!!${name.substring(_YAML_URI_PREFIX.length)}';
    } else {
      return '!<$name>';
    }
  }

  int get hashCode => name.hashCode;
}

/// An enum for kinds of tags.
class TagKind {
  /// A tag indicating that the value is a scalar.
  static const SCALAR = const TagKind._("scalar");

  /// A tag indicating that the value is a sequence.
  static const SEQUENCE = const TagKind._("sequence");

  /// A tag indicating that the value is a mapping.
  static const MAPPING = const TagKind._("mapping");

  final String name;

  const TagKind._(this.name);

  String toString() => name;
}

/// The abstract class for YAML nodes.
abstract class Node {
  /// Every YAML node has a tag that describes its type.
  Tag tag;

  /// Any YAML node can have an anchor associated with it.
  String anchor;

  /// The source span for this node.
  Span span;

  Node(this.tag, this.span, [this.anchor]);

  bool operator ==(other) {
    if (other is! Node) return false;
    return tag == other.tag;
  }

  int get hashCode => tag.hashCode ^ anchor.hashCode;

  visit(Visitor v);
}

/// A sequence node represents an ordered list of nodes.
class SequenceNode extends Node {
  /// The nodes in the sequence.
  List<Node> content;

  SequenceNode(String tagName, this.content, Span span)
    : super(new Tag.sequence(tagName), span);

  /// Two sequences are equal if their tags and contents are equal.
  bool operator ==(other) {
    // Should be super != other; bug 2554
    if (!(super == other) || other is! SequenceNode) return false;
    if (content.length != other.content.length) return false;
    for (var i = 0; i < content.length; i++) {
      if (content[i] != other.content[i]) return false;
    }
    return true;
  }

  String toString() => '$tag [${content.map((e) => '$e').join(', ')}]';

  int get hashCode => super.hashCode ^ deepHashCode(content);

  visit(Visitor v) => v.visitSequence(this);
}

/// An alias node is a reference to an anchor.
class AliasNode extends Node {
  AliasNode(String anchor, Span span)
      : super(new Tag.scalar(Tag.yaml("str")), span, anchor);

  visit(Visitor v) => v.visitAlias(this);
}

/// A scalar node represents all YAML nodes that have a single value.
class ScalarNode extends Node {
  /// The string value of the scalar node, if it was created by the parser.
  final String _content;

  /// The Dart value of the scalar node, if it was created by the composer.
  final value;

  /// Creates a new Scalar node.
  ///
  /// Exactly one of [content] and [value] should be specified. Content should
  /// be specified for a newly-parsed scalar that hasn't yet been composed.
  /// Value should be specified for a composed scalar, although `null` is a
  /// valid value.
  ScalarNode(String tagName, Span span, {String content, this.value})
   : _content = content,
     super(new Tag.scalar(tagName), span);

  /// Two scalars are equal if their string representations are equal.
  bool operator ==(other) {
    // Should be super != other; bug 2554
    if (!(super == other) || other is! ScalarNode) return false;
    return content == other.content;
  }

  /// Returns the string representation of the scalar. After composition, this
  /// is equal to the canonical serialization of the value of the scalar.
  String get content => _content != null ? _content : canonicalContent;

  /// Returns the canonical serialization of the value of the scalar. If the
  /// value isn't given, the result of this will be "null".
  String get canonicalContent {
    if (value == null || value is bool || value is int) return '$value';

    if (value is num) {
      // 20 is the maximum value for this argument, which we use since YAML
      // doesn't specify a maximum.
      return value.toStringAsExponential(20).
        replaceFirst(new RegExp("0+e"), "e");
    }

    if (value is String) {
      // TODO(nweiz): This could be faster if we used a RegExp to check for
      // special characters and short-circuited if they didn't exist.

      var escapedValue = value.codeUnits.map((c) {
        switch (c) {
        case Parser.TAB: return "\\t";
        case Parser.LF: return "\\n";
        case Parser.CR: return "\\r";
        case Parser.DOUBLE_QUOTE: return '\\"';
        case Parser.NULL: return "\\0";
        case Parser.BELL: return "\\a";
        case Parser.BACKSPACE: return "\\b";
        case Parser.VERTICAL_TAB: return "\\v";
        case Parser.FORM_FEED: return "\\f";
        case Parser.ESCAPE: return "\\e";
        case Parser.BACKSLASH: return "\\\\";
        case Parser.NEL: return "\\N";
        case Parser.NBSP: return "\\_";
        case Parser.LINE_SEPARATOR: return "\\L";
        case Parser.PARAGRAPH_SEPARATOR: return "\\P";
        default:
          if (c < 0x20 || (c >= 0x7f && c < 0x100)) {
            return "\\x${zeroPad(c.toRadixString(16).toUpperCase(), 2)}";
          } else if (c >= 0x100 && c < 0x10000) {
            return "\\u${zeroPad(c.toRadixString(16).toUpperCase(), 4)}";
          } else if (c >= 0x10000) {
            return "\\u${zeroPad(c.toRadixString(16).toUpperCase(), 8)}";
          } else {
            return new String.fromCharCodes([c]);
          }
        }
      });
      return '"${escapedValue.join()}"';
    }

    throw new YamlException('Unknown scalar value.', span);
  }

  String toString() => '$tag "$content"';

  /// Left-pads [str] with zeros so that it's at least [length] characters
  /// long.
  String zeroPad(String str, int length) {
    assert(length >= str.length);
    var prefix = new List.filled(length - str.length, '0');
    return '${prefix.join()}$str';
  }

  int get hashCode => super.hashCode ^ content.hashCode;

  visit(Visitor v) => v.visitScalar(this);
}

/// A mapping node represents an unordered map of nodes to nodes.
class MappingNode extends Node {
  /// The node map.
  Map<Node, Node> content;

  MappingNode(String tagName, this.content, Span span)
    : super(new Tag.mapping(tagName), span);

  /// Two mappings are equal if their tags and contents are equal.
  bool operator ==(other) {
    // Should be super != other; bug 2554
    if (!(super == other) || other is! MappingNode) return false;
    if (content.length != other.content.length) return false;
    for (var key in content.keys) {
      if (!other.content.containsKey(key)) return false;
      if (content[key] != other.content[key]) return false;
    }
    return true;
  }

  String toString() {
    var strContent = content.keys
        .map((k) => '${k}: ${content[k]}')
        .join(', ');
    return '$tag {$strContent}';
  }

  int get hashCode => super.hashCode ^ deepHashCode(content);

  visit(Visitor v) => v.visitMapping(this);
}
