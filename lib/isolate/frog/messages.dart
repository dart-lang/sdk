// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Defines message visitors, serialization, and deserialization.

/** Serialize [message] (or simulate serialization). */
_serializeMessage(message) {
  if (_globalState.needSerialization) {
    return new _Serializer().traverse(message);
  } else {
    return new _Copier().traverse(message);
  }
}

/** Deserialize [message] (or simulate deserialization). */
_deserializeMessage(message) {
  if (_globalState.needSerialization) {
    return new _Deserializer().deserialize(message);
  } else {
    // Nothing more to do.
    return message;
  }
}

/** Abstract visitor for dart objects that can be sent as isolate messages. */
class _MessageTraverser {

  List _taggedObjects;

  _MessageTraverser();

  /** Visitor's entry point. */
  traverse(var x) {
    if (isPrimitive(x)) return visitPrimitive(x);
    _taggedObjects = new List();
    var result;
    try {
      result = _dispatch(x);
    } finally {
      _cleanup();
    }
    return result;
  }

  /** Remove all information injected in the native objects by this visitor. */
  void _cleanup() {
    int len = _taggedObjects.length;
    for (int i = 0; i < len; i++) {
      _clearAttachedInfo(_taggedObjects[i]);
    }
    _taggedObjects = null;
  }

  /** Injects into the native object some information used by the visitor. */
  void _attachInfo(var o, var info) {
    _taggedObjects.add(o);
    _setAttachedInfo(o, info);
  }

  /** Retrieves any information stored in the native object [o]. */
  _getInfo(var o) {
    return _getAttachedInfo(o);
  }

  _dispatch(var x) {
    if (isPrimitive(x)) return visitPrimitive(x);
    if (x is List) return visitList(x);
    if (x is Map) return visitMap(x);
    if (x is _NativeJsSendPort) return visitNativeJsSendPort(x);
    if (x is _WorkerSendPort) return visitWorkerSendPort(x);
    if (x is _BufferingSendPort) return visitBufferingSendPort(x);
    // TODO(floitsch): make this a real exception. (which one)?
    throw "Message serialization: Illegal value $x passed";
  }

  abstract visitPrimitive(x);
  abstract visitList(List x);
  abstract visitMap(Map x);
  abstract visitNativeJsSendPort(_NativeJsSendPort x);
  abstract visitWorkerSendPort(_WorkerSendPort x);
  abstract visitBufferingSendPort(_BufferingSendPort x);

  _clearAttachedInfo(var o) native
      "o['__MessageTraverser__attached_info__'] = (void 0);";

  _setAttachedInfo(var o, var info) native
      "o['__MessageTraverser__attached_info__'] = info;";

  _getAttachedInfo(var o) native
      "return o['__MessageTraverser__attached_info__'];";

  _visitNativeOrWorkerPort(SendPort p) {
    if (p is _NativeJsSendPort) return visitNativeJsSendPort(p);
    if (p is _WorkerSendPort) return visitWorkerSendPort(p);
    throw "Illegal underlying port $p";
  }

  static bool isPrimitive(x) {
    return (x === null) || (x is String) || (x is num) || (x is bool);
  }
}


/** A visitor that recursively copies a message. */
class _Copier extends _MessageTraverser {
  _Copier() : super();

  visitPrimitive(x) => x;

  List visitList(List list) {
    List copy = _getInfo(list);
    if (copy !== null) return copy;

    int len = list.length;

    // TODO(floitsch): we loose the generic type of the List.
    copy = new List(len);
    _attachInfo(list, copy);
    for (int i = 0; i < len; i++) {
      copy[i] = _dispatch(list[i]);
    }
    return copy;
  }

  Map visitMap(Map map) {
    Map copy = _getInfo(map);
    if (copy !== null) return copy;

    // TODO(floitsch): we loose the generic type of the map.
    copy = new Map();
    _attachInfo(map, copy);
    map.forEach((key, val) {
      copy[_dispatch(key)] = _dispatch(val);
    });
    return copy;
  }

  SendPort visitNativeJsSendPort(_NativeJsSendPort port) {
    return new _NativeJsSendPort(port._receivePort, port._isolateId);
  }

  SendPort visitWorkerSendPort(_WorkerSendPort port) {
    return new _WorkerSendPort(
        port._workerId, port._isolateId, port._receivePortId);
  }

  SendPort visitBufferingSendPort(_BufferingSendPort port) {
    if (port._port != null) {
      return _visitNativeOrWorkerPort(port._port);
    } else {
      // TODO(floitsch): Use real exception (which one?).
      throw
          "internal error: must call _waitForPendingPorts to ensure all"
          " ports are resolved at this point.";
    }
  }
}

/** Visitor that serializes a message as a JSON array. */
class _Serializer extends _MessageTraverser {
  int _nextFreeRefId = 0;

  _Serializer() : super();

  visitPrimitive(x) => x;

  visitList(List list) {
    int copyId = _getInfo(list);
    if (copyId !== null) return ['ref', copyId];

    int id = _nextFreeRefId++;
    _attachInfo(list, id);
    var jsArray = _serializeList(list);
    // TODO(floitsch): we are losing the generic type.
    return ['list', id, jsArray];
  }

  visitMap(Map map) {
    int copyId = _getInfo(map);
    if (copyId !== null) return ['ref', copyId];

    int id = _nextFreeRefId++;
    _attachInfo(map, id);
    var keys = _serializeList(map.getKeys());
    var values = _serializeList(map.getValues());
    // TODO(floitsch): we are losing the generic type.
    return ['map', id, keys, values];
  }

  visitNativeJsSendPort(_NativeJsSendPort port) {
    return ['sendport', _globalState.currentManagerId,
        port._isolateId, port._receivePort._id];
  }

  visitWorkerSendPort(_WorkerSendPort port) {
    return ['sendport', port._workerId, port._isolateId, port._receivePortId];
  }

  visitBufferingSendPort(_BufferingSendPort port) {
    if (port._port != null) {
      return _visitNativeOrWorkerPort(port._port);
    } else {
      // TODO(floitsch): Use real exception (which one?).
      throw
          "internal error: must call _waitForPendingPorts to ensure all"
          " ports are resolved at this point.";
    }
  }

  _serializeList(List list) {
    int len = list.length;
    var result = new List(len);
    for (int i = 0; i < len; i++) {
      result[i] = _dispatch(list[i]);
    }
    return result;
  }
}

/** Deserializes arrays created with [_Serializer]. */
class _Deserializer {
  Map<int, Dynamic> _deserialized;

  _Deserializer();

  static bool isPrimitive(x) {
    return (x === null) || (x is String) || (x is num) || (x is bool);
  }

  deserialize(x) {
    if (isPrimitive(x)) return x;
    // TODO(floitsch): this should be new HashMap<int, var|Dynamic>()
    _deserialized = new HashMap();
    return _deserializeHelper(x);
  }

  _deserializeHelper(x) {
    if (isPrimitive(x)) return x;
    assert(x is List);
    switch (x[0]) {
      case 'ref': return _deserializeRef(x);
      case 'list': return _deserializeList(x);
      case 'map': return _deserializeMap(x);
      case 'sendport': return _deserializeSendPort(x);
      // TODO(floitsch): Use real exception (which one?).
      default: throw "Unexpected serialized object";
    }
  }

  _deserializeRef(List x) {
    int id = x[1];
    var result = _deserialized[id];
    assert(result !== null);
    return result;
  }

  List _deserializeList(List x) {
    int id = x[1];
    // We rely on the fact that Dart-lists are directly mapped to Js-arrays.
    List dartList = x[2];
    _deserialized[id] = dartList;
    int len = dartList.length;
    for (int i = 0; i < len; i++) {
      dartList[i] = _deserializeHelper(dartList[i]);
    }
    return dartList;
  }

  Map _deserializeMap(List x) {
    Map result = new Map();
    int id = x[1];
    _deserialized[id] = result;
    List keys = x[2];
    List values = x[3];
    int len = keys.length;
    assert(len == values.length);
    for (int i = 0; i < len; i++) {
      var key = _deserializeHelper(keys[i]);
      var value = _deserializeHelper(values[i]);
      result[key] = value;
    }
    return result;
  }

  SendPort _deserializeSendPort(List x) {
    int managerId = x[1];
    int isolateId = x[2];
    int receivePortId = x[3];
    // If two isolates are in the same manager, we use NativeJsSendPorts to
    // deliver messages directly without using postMessage.
    if (managerId == _globalState.currentManagerId) {
      var isolate = _globalState.isolates[isolateId];
      if (isolate == null) return null; // Isolate has been closed.
      var receivePort = isolate.lookup(receivePortId);
      return new _NativeJsSendPort(receivePort, isolateId);
    } else {
      return new _WorkerSendPort(managerId, isolateId, receivePortId);
    }
  }
}

// only visible for testing purposes
// TODO(sigmund): remove once we can disable privacy for testing (bug #1882)
class TestingOnly {
  static copy(x) {
    return new _Copier().traverse(x);
  }

  // only visible for testing purposes
  static serialize(x) {
    _Serializer serializer = new _Serializer();
    _Deserializer deserializer = new _Deserializer();
    return deserializer.deserialize(serializer.traverse(x));
  }
}
