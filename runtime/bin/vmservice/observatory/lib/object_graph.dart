// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_graph;

import 'dart:typed_data';

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
  // Never null.
  final int _id;
  // null for VM-heap objects.
  int _size;
  int get size => _size;
  // null for VM-heap objects.
  int _classId;
  int get classId => _classId;
  final List<ObjectVertex> succ = new List<ObjectVertex>();
  ObjectVertex(this._id);
}

// See implementation of ObjectGraph::Serialize for format.
class ObjectGraph {
  final Map<int, ObjectVertex> _idToVertex = new Map<int, ObjectVertex>();

  ObjectVertex _asVertex(int id) {
    return _idToVertex.putIfAbsent(id, () => new ObjectVertex(id));
  }

  void _addFrom(ReadStream stream) {
    ObjectVertex obj = _asVertex(stream.readUnsigned());
    obj._size = stream.readUnsigned();
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
  }

  Iterable<ObjectVertex> get vertices => _idToVertex.values;
}