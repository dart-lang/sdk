// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A [Node] is an abstract base class for all [Node]s parsed from json
/// constraints.
abstract class Node {
  Map<String, dynamic> toJson();
}

/// A [NamedNode] is an abstract base class for all [Node]s that have a name.
abstract class NamedNode extends Node {
  final String name;

  NamedNode(this.name);
}

/// A [UriAndPrefix] is a simple POD data type wrapping a uri and prefix.
class UriAndPrefix {
  final Uri uri;
  final String prefix;

  UriAndPrefix(this.uri, this.prefix);

  @override
  String toString() {
    return '$uri#$prefix';
  }

  static UriAndPrefix fromJson(String json) {
    var uriAndPrefix = json.split('#');
    if (uriAndPrefix.length != 2) {
      throw 'Invalid "import" "uri#prefix" value in $json';
    }
    var uri = Uri.parse(uriAndPrefix[0]);
    var prefix = uriAndPrefix[1];
    return UriAndPrefix(uri, prefix);
  }
}

/// A [ReferenceNode] is a [NamedNode] with a uri and prefix.
class ReferenceNode extends NamedNode {
  final UriAndPrefix _uriAndPrefix;
  Uri get uri => _uriAndPrefix.uri;
  String get prefix => _uriAndPrefix.prefix;

  ReferenceNode(String name, this._uriAndPrefix) : super(name);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'reference',
      'name': name,
      'import': _uriAndPrefix.toString()
    };
  }

  static ReferenceNode fromJson(Map<String, dynamic> nodeJson) {
    if (nodeJson['type'] != 'reference') {
      throw 'Unrecognized type for reference node: ${nodeJson['type']}.';
    }
    return ReferenceNode(
        nodeJson['name'], UriAndPrefix.fromJson(nodeJson['import']));
  }

  @override
  String toString() {
    return 'ReferenceNode(name=$name, uri=$uri, prefix=$prefix)';
  }
}

/// A [CombinerType] defines how to combine multiple [ReferenceNode]s in a
/// single step.
enum CombinerType { fuse, and, or }

CombinerType parseCombinerType(Map<String, dynamic> nodeJson) {
  String type = nodeJson['type'];
  switch (type) {
    case 'fuse':
      return CombinerType.fuse;
    case 'and':
      return CombinerType.and;
    case 'or':
      return CombinerType.or;
    default:
      throw 'Unrecognized Combiner $nodeJson';
  }
}

String combinerTypeToString(CombinerType type) {
  switch (type) {
    case CombinerType.fuse:
      return 'fuse';
    case CombinerType.and:
      return 'and';
    case CombinerType.or:
      return 'or';
  }
  throw 'Unreachable';
}

T _jsonLookup<T>(Map<String, dynamic> nodeJson, String key) {
  var value = nodeJson[key];
  if (value == null) {
    throw 'Missing "$key" key in $nodeJson';
  }
  return value;
}

NamedNode _jsonLookupNode(
    Map<String, dynamic> nodeJson, String key, Map<String, NamedNode> nameMap) {
  var node = nameMap[_jsonLookup(nodeJson, key)];
  if (node == null) {
    throw 'Invalid "$key" name in $nodeJson';
  }
  return node;
}

/// A [CombinerNode] is a [NamedNode] with a list of [ReferenceNode] children
/// and a [CombinerType] for combining them.
class CombinerNode extends NamedNode {
  final CombinerType type;
  final Set<ReferenceNode> nodes;

  CombinerNode(String name, this.type, this.nodes) : super(name);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': combinerTypeToString(type),
      'name': name,
      'nodes': nodes.map((node) => node.name).toList()
    };
  }

  static CombinerNode fromJson(
      Map<String, dynamic> nodeJson, Map<String, NamedNode> nameMap) {
    String name = _jsonLookup(nodeJson, 'name');
    List<dynamic> referencesJson = _jsonLookup(nodeJson, 'nodes');
    Set<ReferenceNode> references = {};
    for (String reference in referencesJson) {
      references.add(nameMap[reference]);
    }
    return CombinerNode(name, parseCombinerType(nodeJson), references);
  }

  @override
  String toString() {
    var nodeNames = nodes.map((node) => node.name).join(', ');
    return 'CombinerNode(name=$name, type=$type, nodes=$nodeNames)';
  }
}

/// A [RelativeOrderNode] is an unnamed [Node] which defines a relative
/// load order between two [NamedNode]s.
class RelativeOrderNode extends Node {
  final NamedNode predecessor;
  final NamedNode successor;

  RelativeOrderNode({this.predecessor, this.successor}) {
    // TODO(joshualitt) make these both required parameters.
    assert(this.predecessor != null && this.successor != null);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'order',
      'predecessor': predecessor.name,
      'successor': successor.name
    };
  }

  static RelativeOrderNode fromJson(
      Map<String, dynamic> nodeJson, Map<String, NamedNode> nameMap) {
    var predecessor = _jsonLookupNode(nodeJson, 'predecessor', nameMap);
    var successor = _jsonLookupNode(nodeJson, 'successor', nameMap);
    return RelativeOrderNode(predecessor: predecessor, successor: successor);
  }

  @override
  String toString() {
    return 'RelativeOrderNode(predecessor=${predecessor.name}, '
        'successor=${successor.name})';
  }
}

/// A builder class for constructing constraint nodes.
typedef ReferenceNodeNamer = String Function(UriAndPrefix);

class ProgramSplitBuilder {
  final Map<String, NamedNode> namedNodes = {};
  ReferenceNodeNamer _referenceNodeNamer;

  /// 'uri#prefix' will become a key to reference this node in other builder
  /// calls.
  String _uriAndPrefixNamer(UriAndPrefix uriAndPrefix) =>
      uriAndPrefix.toString();

  /// Override the default reference node namer.
  set referenceNodeNamer(ReferenceNodeNamer namer) =>
      _referenceNodeNamer = namer;

  /// Returns the [ReferenceNodeNamer] to use for naming.
  ReferenceNodeNamer get referenceNodeNamer =>
      _referenceNodeNamer ?? _uriAndPrefixNamer;

  NamedNode _addNamedNode(NamedNode node) {
    if (namedNodes.containsKey(node.name)) {
      throw 'Node with name ${node.name} already exists: '
          '${namedNodes[node.name]}';
    }
    namedNodes[node.name] = node;
    return node;
  }

  NamedNode _lookupNamedNode(String nodeName) {
    if (!namedNodes.containsKey(nodeName)) {
      throw 'Missing reference node for $nodeName';
    }
    return namedNodes[nodeName];
  }

  /// Returns a [ReferenceNode] referencing [importUriAndPrefix].
  /// [ReferenceNode]s are typically created in bulk, by mapping over a list of
  /// strings of imports in the form 'uri#prefix'. In further builder calls,
  /// created nodes can be referenced by their namers, derived from calling
  /// [referenceNodeNamer] per [ReferenceNode].
  ReferenceNode referenceNode(String importUriAndPrefix) {
    var uriAndPrefix = UriAndPrefix.fromJson(importUriAndPrefix);
    var name = referenceNodeNamer(uriAndPrefix);
    return _addNamedNode(ReferenceNode(name, uriAndPrefix));
  }

  /// Creates an unnamed [RelativeOrderNode] referencing two [NamedNode]s.
  RelativeOrderNode orderNode(String predecessor, String successor) {
    return RelativeOrderNode(
        predecessor: _lookupNamedNode(predecessor),
        successor: _lookupNamedNode(successor));
  }

  /// Creates a [CombinerNode] which can be referenced by [name] in further
  /// calls to the builder.
  CombinerNode combinerNode(String name, Set<String> nodes, CombinerType type) {
    ReferenceNode _lookup(String nodeName) {
      var node = _lookupNamedNode(nodeName);
      if (node is! ReferenceNode) {
        // TODO(joshualitt): Implement nested combiners.
        throw '$name references node $nodeName which is not a ReferenceNode.';
      }
      return node as ReferenceNode;
    }

    return _addNamedNode(CombinerNode(name, type, nodes.map(_lookup).toSet()));
  }

  /// Creates an 'and' [CombinerNode] which can be referenced by [name] in
  /// further calls to the builder.
  CombinerNode andNode(String name, Set<String> nodes) {
    return combinerNode(name, nodes, CombinerType.and);
  }

  /// Creates a 'fuse' [CombinerNode] which can be referenced by [name] in
  /// further calls to the builder.
  CombinerNode fuseNode(String name, Set<String> nodes) {
    return combinerNode(name, nodes, CombinerType.fuse);
  }

  /// Creates an 'or' [CombinerNode] which can be referenced by [name] in
  /// further calls to the builder.
  CombinerNode orNode(String name, Set<String> nodes) {
    return combinerNode(name, nodes, CombinerType.or);
  }
}

/// [ConstraintData] is a data object which contains the results of parsing json
/// program split constraints.
class ConstraintData {
  final List<NamedNode> named;
  final List<RelativeOrderNode> ordered;

  ConstraintData(this.named, this.ordered);
}
