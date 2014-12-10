// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_graph;

import 'dart:typed_data';

import 'dominator_tree.dart';

// Port of dart::ReadStream from vm/datastream.h.
class ReadStream {
  int _cur = 0;
  final ByteData _data;
  
  ReadStream(this._data);
  
  int get pendingBytes => _data.lengthInBytes - _cur;
  
  int readUnsigned() {
    int result = 0;
    int shift = 0;
    while (_data.getUint8(_cur) <= maxUnsignedDataPerByte) {
      result |= _data.getUint8(_cur) << shift;
      shift += dataBitsPerByte;
      ++_cur;
    }
    result |= (_data.getUint8(_cur) & byteMask) << shift;
    ++_cur;
    return result;
  }

  static const int dataBitsPerByte = 7;
  static const int byteMask = (1 << dataBitsPerByte) - 1;
  static const int maxUnsignedDataPerByte = byteMask;
}

class ObjectVertex {
  // Never null. The isolate root has id 0.
  final int _id;
  // null for VM-heap objects.
  int _shallowSize;
  int get shallowSize => _shallowSize;
  int _retainedSize;
  int get retainedSize => _retainedSize;
  // null for VM-heap objects.
  int _classId;
  int get classId => _classId;
  final List<ObjectVertex> succ = new List<ObjectVertex>();
  ObjectVertex(this._id) : _retainedSize = 0;
  String toString() => '$_id,$_shallowSize,$succ';
}

// See implementation of ObjectGraph::Serialize for format.
class ObjectGraph {
  final Map<int, ObjectVertex> _idToVertex = new Map<int, ObjectVertex>();

  ObjectVertex _asVertex(int id) {
    return _idToVertex.putIfAbsent(id, () => new ObjectVertex(id));
  }

  void _addFrom(ReadStream stream) {
    ObjectVertex obj = _asVertex(stream.readUnsigned());
    obj._shallowSize = stream.readUnsigned();
    obj._classId = stream.readUnsigned();
    int last = stream.readUnsigned();
    while (last != 0) {
      obj.succ.add(_asVertex(last));
      last = stream.readUnsigned();
    }
  }

  ObjectGraph(ReadStream reader) {
    while (reader.pendingBytes > 0) {
      _addFrom(reader);
    }
    _computeRetainedSizes();
  }

  Iterable<ObjectVertex> get vertices => _idToVertex.values;

  ObjectVertex get root => _asVertex(0);
  
  void _computeRetainedSizes() {
    // The retained size for an object is the sum of the shallow sizes of
    // all its descendants in the dominator tree (including itself).
    var d = new Dominator();
    for (ObjectVertex u in vertices) {
      if (u.shallowSize != null) {
        u._retainedSize = u.shallowSize;
        d.addEdges(u, u.succ.where((ObjectVertex v) => v.shallowSize != null));
      }
    }
    d.computeDominatorTree(root);
    // Compute all retained sizes "bottom up", starting from the leaves.
    // Keep track of number of remaining children of each vertex.
    var degree = new Map<ObjectVertex, int>();
    for (ObjectVertex u in vertices) {
      var v = d.dominator(u);
      if (v != null) {
        degree[v] = 1 + degree.putIfAbsent(v, () => 0);
      }
    }
    var leaves = new List<ObjectVertex>();
    for (ObjectVertex u in vertices) {
      if (!degree.containsKey(u)) {
        leaves.add(u);
      }
    }
    while (!leaves.isEmpty) {
      var v = leaves.removeLast();
      var u = d.dominator(v);
      if (u == null) continue;
      u._retainedSize += v._retainedSize;
      if (--degree[u] == 0) {
        leaves.add(u);
      }
    }
  }
}