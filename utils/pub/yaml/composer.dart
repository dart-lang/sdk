// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Takes a parsed YAML document (what the spec calls the "serialization tree")
 * and resolves aliases, resolves tags, and parses scalars to produce the
 * "representation graph".
 */
class _Composer extends _Visitor {
  /** The root node of the serialization tree. */
  _Node root;

  /**
   * Map from anchor names to the most recent representation graph node with
   * that anchor.
   */
  Map<String, _Node> anchors;

  /**
   * The next id to use for the represenation graph's anchors. The spec doesn't
   * use anchors in the representation graph, but we do so that the constructor
   * can ensure that the same node in the representation graph produces the same
   * native object.
   */
  int idCounter;

  _Composer(this.root) : this.anchors = <String, _Node>{}, this.idCounter = 0;

  /** Runs the Composer to produce a representation graph. */
  _Node compose() => root.visit(this);

  /** Returns the anchor to which an alias node refers. */
  _Node visitAlias(_AliasNode alias) {
    if (!anchors.containsKey(alias.anchor)) {
      throw new YamlException("no anchor for alias ${alias.anchor}");
    }
    return anchors[alias.anchor];
  }

  /**
   * Parses a scalar node according to its tag, or auto-detects the type if no
   * tag exists. Currently this only supports the YAML core type schema.
   */
  _Node visitScalar(_ScalarNode scalar) {
    if (scalar.tag.name == "!") {
      return setAnchor(scalar, parseString(scalar.content));
    } else if (scalar.tag.name == "?") {
      for (var fn in [parseNull, parseBool, parseInt, parseFloat]) {
        var result = fn(scalar.content);
        if (result != null) return result;
      }
      return setAnchor(scalar, parseString(scalar.content));
    }

    // TODO(nweiz): support the full YAML type repository
    var tagParsers = {
      'null': parseNull, 'bool': parseBool, 'int': parseInt,
      'float': parseFloat, 'str': parseString
    };

    for (var key in tagParsers.keys) {
      if (scalar.tag.name != _Tag.yaml(key)) continue;
      var result = tagParsers[key](scalar.content);
      if (result != null) return setAnchor(scalar, result);
      throw new YamlException('invalid literal for $key: "${scalar.content}"');
    }

    throw new YamlException('undefined tag: "${scalar.tag.name}"');
  }

  /** Assigns a tag to the sequence and recursively composes its contents. */
  _Node visitSequence(_SequenceNode seq) {
    var tagName = seq.tag.name;
    if (tagName != "!" && tagName != "?" && tagName != _Tag.yaml("seq")) {
      throw new YamlException("invalid tag for sequence: ${tagName}");
    }

    var result = setAnchor(seq, new _SequenceNode(_Tag.yaml("seq"), null));
    result.content = super.visitSequence(seq);
    return result;
  }

  /** Assigns a tag to the mapping and recursively composes its contents. */
  _Node visitMapping(_MappingNode map) {
    var tagName = map.tag.name;
    if (tagName != "!" && tagName != "?" && tagName != _Tag.yaml("map")) {
      throw new YamlException("invalid tag for mapping: ${tagName}");
    }

    var result = setAnchor(map, new _MappingNode(_Tag.yaml("map"), null));
    result.content = super.visitMapping(map);
    return result;
  }

  /**
   * If the serialization tree node [anchored] has an anchor, records that
   * that anchor is pointing to the representation graph node [result].
   */
  _Node setAnchor(_Node anchored, _Node result) {
    if (anchored.anchor == null) return result;
    result.anchor = '${idCounter++}';
    anchors[anchored.anchor] = result;
    return result;
  }

  /** Parses a null scalar. */
  _ScalarNode parseNull(String content) {
    if (!new RegExp("^(null|Null|NULL|~|)\$").hasMatch(content)) return null;
    return new _ScalarNode(_Tag.yaml("null"), value: null);
  }

  /** Parses a boolean scalar. */
  _ScalarNode parseBool(String content) {
    var match = new RegExp("^(?:(true|True|TRUE)|(false|False|FALSE))\$").
      firstMatch(content);
    if (match == null) return null;
    return new _ScalarNode(_Tag.yaml("bool"), value: match.group(1) != null);
  }

  /** Parses an integer scalar. */
  _ScalarNode parseInt(String content) {
    var match = new RegExp("^[-+]?[0-9]+\$").firstMatch(content);
    if (match != null) {
      return new _ScalarNode(_Tag.yaml("int"),
          value: Math.parseInt(match.group(0)));
    }

    match = new RegExp("^0o([0-7]+)\$").firstMatch(content);
    if (match != null) {
      // TODO(nweiz): clean this up when Dart can parse an octal string
      var n = 0;
      for (var c in match.group(1).charCodes) {
        n *= 8;
        n += c - 48;
      }
      return new _ScalarNode(_Tag.yaml("int"), value: n);
    }

    match = new RegExp("^0x[0-9a-fA-F]+\$").firstMatch(content);
    if (match != null) {
      return new _ScalarNode(_Tag.yaml("int"),
          value: Math.parseInt(match.group(0)));
    }

    return null;
  }

  /** Parses a floating-point scalar. */
  _ScalarNode parseFloat(String content) {
    var match = new RegExp(
        "^[-+]?(\.[0-9]+|[0-9]+(\.[0-9]*)?)([eE][-+]?[0-9]+)?\$").
      firstMatch(content);
    if (match != null) {
      // YAML allows floats of the form "0.", but Dart does not. Fix up those
      // floats by removing the trailing dot.
      var matchStr = match.group(0).replaceAll(new RegExp(r"\.$"), "");
      return new _ScalarNode(_Tag.yaml("float"),
          value: Math.parseDouble(matchStr));
    }

    match = new RegExp("^([+-]?)\.(inf|Inf|INF)\$").firstMatch(content);
    if (match != null) {
      var infinityStr = match.group(1) == "-" ? "-Infinity" : "Infinity";
      return new _ScalarNode(_Tag.yaml("float"),
          value: Math.parseDouble(infinityStr));
    }

    match = new RegExp("^\.(nan|NaN|NAN)\$").firstMatch(content);
    if (match != null) {
      return new _ScalarNode(_Tag.yaml("float"),
          value: Math.parseDouble("NaN"));
    }

    return null;
  }

  /** Parses a string scalar. */
  _ScalarNode parseString(String content) =>
    new _ScalarNode(_Tag.yaml("str"), value: content);
}
