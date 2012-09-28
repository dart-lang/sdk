// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains the node classes for the internal representations of YAML
// documents. These nodes are used for both the serialization tree and the
// representation graph.

/** A tag that indicates the type of a YAML node. */
class _Tag {
  // TODO(nweiz): it would better match the semantics of the spec if there were
  // a singleton instance of this class for each tag.

  static const SCALAR_KIND = 0;
  static const SEQUENCE_KIND = 1;
  static const MAPPING_KIND = 2;

  static const String YAML_URI_PREFIX = 'tag:yaml.org,2002:';

  /** The name of the tag, either a URI or a local tag beginning with "!". */
  final String name;

  /** The kind of the tag: SCALAR_KIND, SEQUENCE_KIND, or MAPPING_KIND. */
  final int kind;

  _Tag(this.name, this.kind);

  _Tag.scalar(String name) : this(name, SCALAR_KIND);
  _Tag.sequence(String name) : this(name, SEQUENCE_KIND);
  _Tag.mapping(String name) : this(name, MAPPING_KIND);

  /** Returns the standard YAML tag URI for [type]. */
  static String yaml(String type) => "tag:yaml.org,2002:$type";

  /** Two tags are equal if their URIs are equal. */
  operator ==(other) {
    if (other is! _Tag) return false;
    return name == other.name;
  }

  String toString() {
    if (name.startsWith(YAML_URI_PREFIX)) {
      return '!!${name.substring(YAML_URI_PREFIX.length)}';
    } else {
      return '!<$name>';
    }
  }

  int hashCode() => name.hashCode();
}

/** The abstract class for YAML nodes. */
class _Node {
  /** Every YAML node has a tag that describes its type. */
  _Tag tag;

  /** Any YAML node can have an anchor associated with it. */
  String anchor;

  _Node(this.tag, [this.anchor]);

  bool operator ==(other) {
    if (other is! _Node) return false;
    return tag == other.tag;
  }

  int hashCode() => _hashCode([tag, anchor]);

  abstract visit(_Visitor v);
}

/** A sequence node represents an ordered list of nodes. */
class _SequenceNode extends _Node {
  /** The nodes in the sequence. */
  List<_Node> content;

  _SequenceNode(String tagName, this.content)
    : super(new _Tag.sequence(tagName));

  /** Two sequences are equal if their tags and contents are equal. */
  bool operator ==(other) {
    // Should be super != other; bug 2554
    if (!(super == other) || other is! _SequenceNode) return false;
    if (content.length != other.content.length) return false;
    for (var i = 0; i < content.length; i++) {
      if (content[i] != other.content[i]) return false;
    }
    return true;
  }

  String toString() => '$tag [${Strings.join(content.map((e) => '$e'), ', ')}]';

  int hashCode() => super.hashCode() ^ _hashCode(content);

  visit(_Visitor v) => v.visitSequence(this);
}

/** An alias node is a reference to an anchor. */
class _AliasNode extends _Node {
  _AliasNode(String anchor) : super(new _Tag.scalar(_Tag.yaml("str")), anchor);

  visit(_Visitor v) => v.visitAlias(this);
}

/** A scalar node represents all YAML nodes that have a single value. */
class _ScalarNode extends _Node {
  /** The string value of the scalar node, if it was created by the parser. */
  final String _content;

  /** The Dart value of the scalar node, if it was created by the composer. */
  final value;

  /**
   * Creates a new Scalar node.
   *
   * Exactly one of [content] and [value] should be specified. Content should be
   * specified for a newly-parsed scalar that hasn't yet been composed. Value
   * should be specified for a composed scalar, although `null` is a valid
   * value.
   */
  _ScalarNode(String tagName, [String content, this.value])
   : _content = content,
     super(new _Tag.scalar(tagName));

  /** Two scalars are equal if their string representations are equal. */
  bool operator ==(other) {
    // Should be super != other; bug 2554
    if (!(super == other) || other is! _ScalarNode) return false;
    return content == other.content;
  }

  /**
   * Returns the string representation of the scalar. After composition, this is
   * equal to the canonical serialization of the value of the scalar.
   */
  String get content => _content != null ? _content : canonicalContent;

  /**
   * Returns the canonical serialization of the value of the scalar. If the
   * value isn't given, the result of this will be "null".
   */
  String get canonicalContent {
    if (value == null || value is bool || value is int) return '$value';

    if (value is num) {
      // 20 is the maximum value for this argument, which we use since YAML
      // doesn't specify a maximum.
      return value.toStringAsExponential(20).
        replaceFirst(const RegExp("0+e"), "e");
    }

    if (value is String) {
      // TODO(nweiz): This could be faster if we used a RegExp to check for
      // special characters and short-circuited if they didn't exist.

      var escapedValue = value.charCodes().map((c) {
        switch (c) {
        case _Parser.TAB: return "\\t";
        case _Parser.LF: return "\\n";
        case _Parser.CR: return "\\r";
        case _Parser.DOUBLE_QUOTE: return '\\"';
        case _Parser.NULL: return "\\0";
        case _Parser.BELL: return "\\a";
        case _Parser.BACKSPACE: return "\\b";
        case _Parser.VERTICAL_TAB: return "\\v";
        case _Parser.FORM_FEED: return "\\f";
        case _Parser.ESCAPE: return "\\e";
        case _Parser.BACKSLASH: return "\\\\";
        case _Parser.NEL: return "\\N";
        case _Parser.NBSP: return "\\_";
        case _Parser.LINE_SEPARATOR: return "\\L";
        case _Parser.PARAGRAPH_SEPARATOR: return "\\P";
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
      return '"${Strings.join(escapedValue, '')}"';
    }

    throw new YamlException("unknown scalar value: $value");
  }

  String toString() => '$tag "$content"';

  /**
   * Left-pads [str] with zeros so that it's at least [length] characters
   * long.
   */
  String zeroPad(String str, int length) {
    assert(length >= str.length);
    var prefix = [];
    prefix.insertRange(0, length - str.length, '0');
    return '${Strings.join(prefix, '')}$str';
  }

  int hashCode() => super.hashCode() ^ content.hashCode();

  visit(_Visitor v) => v.visitScalar(this);
}

/** A mapping node represents an unordered map of nodes to nodes. */
class _MappingNode extends _Node {
  /** The node map. */
  Map<_Node, _Node> content;

  _MappingNode(String tagName, this.content)
    : super(new _Tag.mapping(tagName));

  /** Two mappings are equal if their tags and contents are equal. */
  bool operator ==(other) {
    // Should be super != other; bug 2554
    if (!(super == other) || other is! _MappingNode) return false;
    if (content.length != other.content.length) return false;
    for (var key in content.getKeys()) {
      if (!other.content.containsKey(key)) return false;
      if (content[key] != other.content[key]) return false;
    }
    return true;
  }

  String toString() {
    var strContent = Strings.join(content.getKeys().
        map((k) => '${k}: ${content[k]}'), ', ');
    return '$tag {$strContent}';
  }

  int hashCode() => super.hashCode() ^ _hashCode(content);

  visit(_Visitor v) => v.visitMapping(this);
}
