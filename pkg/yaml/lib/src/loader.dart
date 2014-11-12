// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.loader;

import 'package:source_span/source_span.dart';

import 'equality.dart';
import 'event.dart';
import 'parser.dart';
import 'yaml_document.dart';
import 'yaml_exception.dart';
import 'yaml_node.dart';

/// A loader that reads [Event]s emitted by a [Parser] and emits
/// [YamlDocument]s.
///
/// This is based on the libyaml loader, available at
/// https://github.com/yaml/libyaml/blob/master/src/loader.c. The license for
/// that is available in ../../libyaml-license.txt.
class Loader {
  /// The underlying [Parser] that generates [Event]s.
  final Parser _parser;

  /// Aliases by the alias name.
  final _aliases = new Map<String, YamlNode>();

  /// The span of the entire stream emitted so far.
  FileSpan get span => _span;
  FileSpan _span;

  /// Creates a loader that loads [source].
  ///
  /// [sourceUrl] can be a String or a [Uri].
  Loader(String source, {sourceUrl})
      : _parser = new Parser(source, sourceUrl: sourceUrl) {
    var event = _parser.parse();
    _span = event.span;
    assert(event.type == EventType.STREAM_START);
  }

  /// Loads the next document from the stream.
  ///
  /// If there are no more documents, returns `null`.
  YamlDocument load() {
    if (_parser.isDone) return null;

    var event = _parser.parse();
    if (event.type == EventType.STREAM_END) {
      _span = _span.expand(event.span);
      return null;
    }

    var document = _loadDocument(event);
    _span = _span.expand(document.span);
    _aliases.clear();
    return document;
  }

  /// Composes a document object.
  YamlDocument _loadDocument(DocumentStartEvent firstEvent) {
    var contents = _loadNode(_parser.parse());

    var lastEvent = _parser.parse();
    assert(lastEvent.type == EventType.DOCUMENT_END);

    return new YamlDocument.internal(
        contents,
        firstEvent.span.expand(lastEvent.span),
        firstEvent.versionDirective,
        firstEvent.tagDirectives,
        startImplicit: firstEvent.isImplicit,
        endImplicit: lastEvent.isImplicit);
  }

  /// Composes a node.
  YamlNode _loadNode(Event firstEvent) {
    switch (firstEvent.type) {
      case EventType.ALIAS: return _loadAlias(firstEvent);
      case EventType.SCALAR: return _loadScalar(firstEvent);
      case EventType.SEQUENCE_START: return _loadSequence(firstEvent);
      case EventType.MAPPING_START: return _loadMapping(firstEvent);
      default: throw "Unreachable";
    }
  }

  /// Registers an anchor.
  void _registerAnchor(String anchor, YamlNode node) {
    if (anchor == null) return;

    // libyaml throws an error for duplicate anchors, but example 7.1 makes it
    // clear that they should be overridden:
    // http://yaml.org/spec/1.2/spec.html#id2786448.

    _aliases[anchor] = node;
  }

  /// Composes a node corresponding to an alias.
  YamlNode _loadAlias(AliasEvent event) {
    var alias = _aliases[event.name];
    if (alias != null) return alias;

    throw new YamlException("Undefined alias.", event.span);
  }

  /// Composes a scalar node.
  YamlNode _loadScalar(ScalarEvent scalar) {
    var node;
    if (scalar.tag == "!") {
      node = _parseString(scalar);
    } else if (scalar.tag != null) {
      node = _parseByTag(scalar);
    } else {
      node = _parseNull(scalar);
      if (node == null) node = _parseBool(scalar);
      if (node == null) node = _parseInt(scalar);
      if (node == null) node = _parseFloat(scalar);
      if (node == null) node = _parseString(scalar);
    }

    _registerAnchor(scalar.anchor, node);
    return node;
  }

  /// Composes a sequence node.
  YamlNode _loadSequence(SequenceStartEvent firstEvent) {
    if (firstEvent.tag != "!" && firstEvent.tag != null &&
        firstEvent.tag != "tag:yaml.org,2002:seq") {
      throw new YamlException("Invalid tag for sequence.", firstEvent.span);
    }

    var children = [];
    var node = new YamlList.internal(
        children, firstEvent.span, firstEvent.style);
    _registerAnchor(firstEvent.anchor, node);

    var event = _parser.parse();
    while (event.type != EventType.SEQUENCE_END) {
      children.add(_loadNode(event));
      event = _parser.parse();
    }

    setSpan(node, firstEvent.span.expand(event.span));
    return node;
  }

  /// Composes a mapping node.
  YamlNode _loadMapping(MappingStartEvent firstEvent) {
    if (firstEvent.tag != "!" && firstEvent.tag != null &&
        firstEvent.tag != "tag:yaml.org,2002:map") {
      throw new YamlException("Invalid tag for mapping.", firstEvent.span);
    }

    var children = deepEqualsMap();
    var node = new YamlMap.internal(
        children, firstEvent.span, firstEvent.style);
    _registerAnchor(firstEvent.anchor, node);

    var event = _parser.parse();
    while (event.type != EventType.MAPPING_END) {
      var key = _loadNode(event);
      var value = _loadNode(_parser.parse());
      children[key] = value;
      event = _parser.parse();
    }

    setSpan(node, firstEvent.span.expand(event.span));
    return node;
  }

  /// Parses a scalar according to its tag name.
  YamlScalar _parseByTag(ScalarEvent scalar) {
    switch (scalar.tag) {
      case "tag:yaml.org,2002:null": return _parseNull(scalar);
      case "tag:yaml.org,2002:bool": return _parseBool(scalar);
      case "tag:yaml.org,2002:int": return _parseInt(scalar);
      case "tag:yaml.org,2002:float": return _parseFloat(scalar);
      case "tag:yaml.org,2002:str": return _parseString(scalar);
    }
    throw new YamlException('Undefined tag: ${scalar.tag}.', scalar.span);
  }

  /// Parses a null scalar.
  YamlScalar _parseNull(ScalarEvent scalar) {
    // TODO(nweiz): stop using regexps.
    // TODO(nweiz): add ScalarStyle and implicit metadata to the scalars.
    if (new RegExp(r"^(null|Null|NULL|~|)$").hasMatch(scalar.value)) {
      return new YamlScalar.internal(null, scalar.span, scalar.style);
    } else {
      return null;
    }
  }

  /// Parses a boolean scalar.
  YamlScalar _parseBool(ScalarEvent scalar) {
    var match = new RegExp(r"^(?:(true|True|TRUE)|(false|False|FALSE))$").
        firstMatch(scalar.value);
    if (match == null) return null;
    return new YamlScalar.internal(
        match.group(1) != null, scalar.span, scalar.style);
  }

  /// Parses an integer scalar.
  YamlScalar _parseInt(ScalarEvent scalar) {
    var match = new RegExp(r"^[-+]?[0-9]+$").firstMatch(scalar.value);
    if (match != null) {
      return new YamlScalar.internal(
          int.parse(match.group(0)), scalar.span, scalar.style);
    }

    match = new RegExp(r"^0o([0-7]+)$").firstMatch(scalar.value);
    if (match != null) {
      var n = int.parse(match.group(1), radix: 8);
      return new YamlScalar.internal(n, scalar.span, scalar.style);
    }

    match = new RegExp(r"^0x[0-9a-fA-F]+$").firstMatch(scalar.value);
    if (match != null) {
      return new YamlScalar.internal(
          int.parse(match.group(0)), scalar.span, scalar.style);
    }

    return null;
  }

  /// Parses a floating-point scalar.
  YamlScalar _parseFloat(ScalarEvent scalar) {
    var match = new RegExp(
          r"^[-+]?(\.[0-9]+|[0-9]+(\.[0-9]*)?)([eE][-+]?[0-9]+)?$").
        firstMatch(scalar.value);
    if (match != null) {
      // YAML allows floats of the form "0.", but Dart does not. Fix up those
      // floats by removing the trailing dot.
      var matchStr = match.group(0).replaceAll(new RegExp(r"\.$"), "");
      return new YamlScalar.internal(
          double.parse(matchStr), scalar.span, scalar.style);
    }

    match = new RegExp(r"^([+-]?)\.(inf|Inf|INF)$").firstMatch(scalar.value);
    if (match != null) {
      var value = match.group(1) == "-" ? -double.INFINITY : double.INFINITY;
      return new YamlScalar.internal(value, scalar.span, scalar.style);
    }

    match = new RegExp(r"^\.(nan|NaN|NAN)$").firstMatch(scalar.value);
    if (match != null) {
      return new YamlScalar.internal(double.NAN, scalar.span, scalar.style);
    }

    return null;
  }

  /// Parses a string scalar.
  YamlScalar _parseString(ScalarEvent scalar) =>
      new YamlScalar.internal(scalar.value, scalar.span, scalar.style);
}
