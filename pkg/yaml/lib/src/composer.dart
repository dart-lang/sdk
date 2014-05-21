// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.composer;

import 'model.dart';
import 'visitor.dart';
import 'yaml_exception.dart';

/// Takes a parsed YAML document (what the spec calls the "serialization tree")
/// and resolves aliases, resolves tags, and parses scalars to produce the
/// "representation graph".
class Composer extends Visitor {
  /// The root node of the serialization tree.
  final Node _root;

  /// Map from anchor names to the most recent representation graph node with
  /// that anchor.
  final _anchors = <String, Node>{};

  /// The next id to use for the represenation graph's anchors.
  ///
  /// The spec doesn't use anchors in the representation graph, but we do so
  /// that the constructor can ensure that the same node in the representation
  /// graph produces the same native object.
  var _idCounter = 0;

  Composer(this._root);

  /// Runs the Composer to produce a representation graph.
  Node compose() => _root.visit(this);

  /// Returns the anchor to which an alias node refers.
  Node visitAlias(AliasNode alias) {
    if (!_anchors.containsKey(alias.anchor)) {
      throw new YamlException("No anchor for alias ${alias.anchor}.");
    }
    return _anchors[alias.anchor];
  }

  /// Parses a scalar node according to its tag, or auto-detects the type if no
  /// tag exists.
  ///
  /// Currently this only supports the YAML core type schema.
  Node visitScalar(ScalarNode scalar) {
    if (scalar.tag.name == "!") {
      return setAnchor(scalar, parseString(scalar.content));
    } else if (scalar.tag.name == "?") {
      for (var fn in [parseNull, parseBool, parseInt, parseFloat]) {
        var result = fn(scalar.content);
        if (result != null) return result;
      }
      return setAnchor(scalar, parseString(scalar.content));
    }

    var result = _parseByTag(scalar);
    if (result != null) return setAnchor(scalar, result);
    throw new YamlException('Invalid literal for ${scalar.tag}: '
        '"${scalar.content}".');
  }

  ScalarNode _parseByTag(ScalarNode scalar) {
    switch (scalar.tag.name) {
      case "null": return parseNull(scalar.content);
      case "bool": return parseBool(scalar.content);
      case "int": return parseInt(scalar.content);
      case "float": return parseFloat(scalar.content);
      case "str": return parseString(scalar.content);
    }
    throw new YamlException('Undefined tag: ${scalar.tag}.');
  }

  /// Assigns a tag to the sequence and recursively composes its contents.
  Node visitSequence(SequenceNode seq) {
    var tagName = seq.tag.name;
    if (tagName != "!" && tagName != "?" && tagName != Tag.yaml("seq")) {
      throw new YamlException("Invalid tag for sequence: ${seq.tag}.");
    }

    var result = setAnchor(seq, new SequenceNode(Tag.yaml('seq'), null));
    result.content = super.visitSequence(seq);
    return result;
  }

  /// Assigns a tag to the mapping and recursively composes its contents.
  Node visitMapping(MappingNode map) {
    var tagName = map.tag.name;
    if (tagName != "!" && tagName != "?" && tagName != Tag.yaml("map")) {
      throw new YamlException("Invalid tag for mapping: ${map.tag}.");
    }

    var result = setAnchor(map, new MappingNode(Tag.yaml('map'), null));
    result.content = super.visitMapping(map);
    return result;
  }

  /// If the serialization tree node [anchored] has an anchor, records that
  /// that anchor is pointing to the representation graph node [result].
  Node setAnchor(Node anchored, Node result) {
    if (anchored.anchor == null) return result;
    result.anchor = '${_idCounter++}';
    _anchors[anchored.anchor] = result;
    return result;
  }

  /// Parses a null scalar.
  ScalarNode parseNull(String content) {
    if (!new RegExp(r"^(null|Null|NULL|~|)$").hasMatch(content)) return null;
    return new ScalarNode(Tag.yaml("null"), value: null);
  }

  /// Parses a boolean scalar.
  ScalarNode parseBool(String content) {
    var match = new RegExp(r"^(?:(true|True|TRUE)|(false|False|FALSE))$").
      firstMatch(content);
    if (match == null) return null;
    return new ScalarNode(Tag.yaml("bool"), value: match.group(1) != null);
  }

  /// Parses an integer scalar.
  ScalarNode parseInt(String content) {
    var match = new RegExp(r"^[-+]?[0-9]+$").firstMatch(content);
    if (match != null) {
      return new ScalarNode(Tag.yaml("int"),
          value: int.parse(match.group(0)));
    }

    match = new RegExp(r"^0o([0-7]+)$").firstMatch(content);
    if (match != null) {
      int n = int.parse(match.group(1), radix: 8);
      return new ScalarNode(Tag.yaml("int"), value: n);
    }

    match = new RegExp(r"^0x[0-9a-fA-F]+$").firstMatch(content);
    if (match != null) {
      return new ScalarNode(Tag.yaml("int"),
          value: int.parse(match.group(0)));
    }

    return null;
  }

  /// Parses a floating-point scalar.
  ScalarNode parseFloat(String content) {
    var match = new RegExp(
        r"^[-+]?(\.[0-9]+|[0-9]+(\.[0-9]*)?)([eE][-+]?[0-9]+)?$").
      firstMatch(content);
    if (match != null) {
      // YAML allows floats of the form "0.", but Dart does not. Fix up those
      // floats by removing the trailing dot.
      var matchStr = match.group(0).replaceAll(new RegExp(r"\.$"), "");
      return new ScalarNode(Tag.yaml("float"),
          value: double.parse(matchStr));
    }

    match = new RegExp(r"^([+-]?)\.(inf|Inf|INF)$").firstMatch(content);
    if (match != null) {
      var value = match.group(1) == "-" ? -double.INFINITY : double.INFINITY;
      return new ScalarNode(Tag.yaml("float"), value: value);
    }

    match = new RegExp(r"^\.(nan|NaN|NAN)$").firstMatch(content);
    if (match != null) {
      return new ScalarNode(Tag.yaml("float"), value: double.NAN);
    }

    return null;
  }

  /// Parses a string scalar.
  ScalarNode parseString(String content) =>
    new ScalarNode(Tag.yaml("str"), value: content);
}
