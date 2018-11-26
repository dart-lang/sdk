// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:dart2js_info/src/graph.dart";

class _NodeInfo {
  int type;
  int name;
  int id;
  int selfSize;
  int edgeCount;
  _NodeInfo(
    this.type,
    this.name,
    this.id,
    this.selfSize,
    this.edgeCount,
  );
}

const List<String> _kRequiredNodeFields = [
  "type",
  "name",
  "id",
  "self_size",
  "edge_count",
];

class _EdgeInfo {
  int type;
  int nameOrIndex;
  int nodeOffset;
  _EdgeInfo(
    this.type,
    this.nameOrIndex,
    this.nodeOffset,
  );
}

const List<String> _kRequiredEdgeFields = [
  "type",
  "name_or_index",
  "to_node",
];

class NodeInfo {
  String type;
  String name;
  int id;
  int selfSize;
  NodeInfo(
    this.type,
    this.name,
    this.id,
    this.selfSize,
  );
}

class V8SnapshotProfile extends Graph<int> {
  // Indexed by node offset.
  final Map<int, _NodeInfo> _nodes = {};

  // Indexed by start node offset.
  final Map<int, List<_EdgeInfo>> _toEdges = {};
  final Map<int, List<_EdgeInfo>> _fromEdges = {};

  List<String> _nodeFields = [];
  List<String> _edgeFields = [];

  List<String> _nodeTypes = [];
  List<String> _edgeTypes = [];

  List<String> _strings = [];

  // Only used to ensure IDs are unique.
  Set<int> _ids = Set<int>();

  V8SnapshotProfile.fromJson(Map top) {
    final Map snapshot = top["snapshot"];
    _parseMetadata(snapshot["meta"]);

    _parseStrings(top["strings"]);
    Expect.equals(snapshot["node_count"], _parseNodes(top["nodes"]));
    Expect.equals(snapshot["edge_count"], _parseEdges(top["edges"]));

    _calculateFromEdges();
  }

  void _parseMetadata(Map meta) {
    final List nodeFields = meta["node_fields"];
    nodeFields.forEach(_nodeFields.add);
    Expect.isTrue(_kRequiredNodeFields.every(_nodeFields.contains));

    final List edgeFields = meta["edge_fields"];
    edgeFields.forEach(_edgeFields.add);
    Expect.isTrue(_kRequiredEdgeFields.every(_edgeFields.contains));

    // First entry of "node_types" is an array with the actual node types. IDK
    // what the other entries are for.
    List nodeTypes = meta["node_types"];
    nodeTypes = nodeTypes[0];
    nodeTypes.forEach(_nodeTypes.add);

    // Same for edges.
    List edgeTypes = meta["edge_types"];
    edgeTypes = edgeTypes[0];
    edgeTypes.forEach(_edgeTypes.add);
  }

  int _parseNodes(List nodes) {
    final int typeIndex = _nodeFields.indexOf("type");
    final int nameIndex = _nodeFields.indexOf("name");
    final int idIndex = _nodeFields.indexOf("id");
    final int selfSizeIndex = _nodeFields.indexOf("self_size");
    final int edgeCountIndex = _nodeFields.indexOf("edge_count");

    int offset = 0;
    for (; offset < nodes.length; offset += _nodeFields.length) {
      final int type = nodes[offset + typeIndex];
      Expect.isTrue(0 <= type && type < _nodeTypes.length);

      final int name = nodes[offset + nameIndex];
      Expect.isTrue(0 <= name && name < _strings.length);

      final int id = nodes[offset + idIndex];
      Expect.isTrue(id >= 0);
      Expect.isFalse(_ids.contains(id));
      _ids.add(id);

      final int selfSize = nodes[offset + selfSizeIndex];
      Expect.isTrue(selfSize >= 0);

      final int edgeCount = nodes[offset + edgeCountIndex];
      Expect.isTrue(edgeCount >= 0);

      _nodes[offset] = _NodeInfo(type, name, id, selfSize, edgeCount);
    }

    Expect.equals(offset, nodes.length);
    return offset ~/ _nodeFields.length;
  }

  int _parseEdges(List edges) {
    final int typeIndex = _edgeFields.indexOf("type");
    final int nameOrIndexIndex = _edgeFields.indexOf("name_or_index");
    final int toNodeIndex = _edgeFields.indexOf("to_node");

    int edgeOffset = 0;
    for (int nodeOffset = 0;
        nodeOffset < _nodes.length * _nodeFields.length;
        nodeOffset += _nodeFields.length) {
      final int edgeCount = _nodes[nodeOffset].edgeCount;
      final List<_EdgeInfo> nodeEdges = List<_EdgeInfo>(edgeCount);
      for (int i = 0; i < edgeCount; ++i, edgeOffset += _edgeFields.length) {
        final int type = edges[edgeOffset + typeIndex];
        Expect.isTrue(0 <= type && type < _edgeTypes.length);

        final int nameOrIndex = edges[edgeOffset + nameOrIndexIndex];
        if (_edgeTypes[type] == "property") {
          Expect.isTrue(0 <= nameOrIndex && nameOrIndex < _strings.length);
        } else if (_edgeTypes[type] == "element") {
          Expect.isTrue(nameOrIndex >= 0);
        }

        final int toNode = edges[edgeOffset + toNodeIndex];
        checkNode(toNode);
        nodeEdges[i] = _EdgeInfo(type, nameOrIndex, toNode);
      }
      _toEdges[nodeOffset] = nodeEdges;
    }

    Expect.equals(edgeOffset, edges.length);
    return edgeOffset ~/ _edgeFields.length;
  }

  void checkNode(int offset) {
    Expect.isTrue(offset >= 0 &&
        offset % _nodeFields.length == 0 &&
        offset ~/ _nodeFields.length < _nodes.length);
  }

  void _calculateFromEdges() {
    for (final MapEntry<int, List<_EdgeInfo>> entry in _toEdges.entries) {
      final int fromNode = entry.key;
      for (final _EdgeInfo edge in entry.value) {
        final List<_EdgeInfo> backEdges =
            _fromEdges.putIfAbsent(edge.nodeOffset, () => <_EdgeInfo>[]);
        backEdges.add(_EdgeInfo(edge.type, edge.nameOrIndex, fromNode));
      }
    }
  }

  void _parseStrings(List strings) => strings.forEach(_strings.add);

  int get accountedBytes {
    int sum = 0;
    for (final _NodeInfo info in _nodes.values) {
      sum += info.selfSize;
    }
    return sum;
  }

  int get unknownCount {
    final int unknownType = _nodeTypes.indexOf("Unknown");
    Expect.isTrue(unknownType >= 0);

    int count = 0;
    for (final MapEntry<int, _NodeInfo> entry in _nodes.entries) {
      if (entry.value.type == unknownType) {
        ++count;
      }
    }
    return count;
  }

  bool get isEmpty => _nodes.isEmpty;
  int get nodeCount => _nodes.length;

  Iterable<int> get nodes => _nodes.keys;

  Iterable<int> targetsOf(int source) {
    return _toEdges[source].map((_EdgeInfo i) => i.nodeOffset);
  }

  Iterable<int> sourcesOf(int source) {
    return _fromEdges[source].map((_EdgeInfo i) => i.nodeOffset);
  }

  int get root => 0;

  NodeInfo operator [](int node) {
    _NodeInfo info = _nodes[node];
    final type = info.type != null ? _nodeTypes[info.type] : null;
    final name = info.name != null ? _strings[info.name] : null;
    return NodeInfo(type, name, info.id, info.selfSize);
  }
}
