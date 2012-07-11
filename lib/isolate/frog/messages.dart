// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Defines message visitors, serialization, and deserialization.

/** Serialize [message] (or simulate serialization). */
_serializeMessage(message) {
  if (_globalState.needSerialization) {
    return new _JsSerializer().traverse(message);
  } else {
    return new _JsCopier().traverse(message);
  }
}

/** Deserialize [message] (or simulate deserialization). */
_deserializeMessage(message) {
  if (_globalState.needSerialization) {
    return new _JsDeserializer().deserialize(message);
  } else {
    // Nothing more to do.
    return message;
  }
}

class _JsSerializer extends _Serializer {

  _JsSerializer() : super() { _visited = new _JsVisitedMap(); }

  visitSendPort(SendPort x) {
    if (x is _NativeJsSendPort) return visitNativeJsSendPort(x);
    if (x is _WorkerSendPort) return visitWorkerSendPort(x);
    if (x is _BufferingSendPort) return visitBufferingSendPort(x);
    throw "Illegal underlying port $x";
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
      return visitSendPort(port._port);
    } else {
      // TODO(floitsch): Use real exception (which one?).
      throw
          "internal error: must call _waitForPendingPorts to ensure all"
          " ports are resolved at this point.";
    }
  }

}


class _JsCopier extends _Copier {

  _JsCopier() : super() { _visited = new _JsVisitedMap(); }

  visitSendPort(SendPort x) {
    if (x is _NativeJsSendPort) return visitNativeJsSendPort(x);
    if (x is _WorkerSendPort) return visitWorkerSendPort(x);
    if (x is _BufferingSendPort) return visitBufferingSendPort(x);
    throw "Illegal underlying port $p";
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
      return visitSendPort(port._port);
    } else {
      // TODO(floitsch): Use real exception (which one?).
      throw
          "internal error: must call _waitForPendingPorts to ensure all"
          " ports are resolved at this point.";
    }
  }

}

class _JsDeserializer extends _Deserializer {

  SendPort deserializeSendPort(List x) {
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

class _JsVisitedMap implements _MessageTraverserVisitedMap {
  List tagged;

  /** Retrieves any information stored in the native object [object]. */
  operator[](var object) {
    return _getAttachedInfo(object);
  }

  /** Injects some information into the native [object]. */
  void operator[]=(var object, var info) {
    tagged.add(object);
    _setAttachedInfo(object, info);
  }

  /** Get ready to rumble. */
  void reset() {
    assert(tagged == null);
    tagged = new List();
  }

  /** Remove all information injected in the native objects. */
  cleanup() {
    for (int i = 0, length = tagged.length; i < length; i++) {
      _clearAttachedInfo(tagged[i]);
    }
    tagged = null;
  }

  _clearAttachedInfo(var o) native
      "o['__MessageTraverser__attached_info__'] = (void 0);";

  _setAttachedInfo(var o, var info) native
      "o['__MessageTraverser__attached_info__'] = info;";

  _getAttachedInfo(var o) native
      "return o['__MessageTraverser__attached_info__'];";
}

// only visible for testing purposes
// TODO(sigmund): remove once we can disable privacy for testing (bug #1882)
class TestingOnly {
  static copy(x) {
    return new _JsCopier().traverse(x);
  }

  // only visible for testing purposes
  static serialize(x) {
    _Serializer serializer = new _JsSerializer();
    _Deserializer deserializer = new _JsDeserializer();
    return deserializer.deserialize(serializer.traverse(x));
  }
}
