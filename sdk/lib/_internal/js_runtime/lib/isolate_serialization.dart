// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _isolate_helper;

/// Serialize [message].
_serializeMessage(message) {
  return new _Serializer().serialize(message);
}

/// Deserialize [message].
_deserializeMessage(message) {
  return new _Deserializer().deserialize(message);
}

bool _isIsolateMessage(message) {
  if (_isPrimitive(message)) return true;
  if (message is! JSArray) return false;
  if (message.isEmpty) return false;
  switch (message.first) {
    case "ref":
    case "buffer":
    case "typed":
    case "fixed":
    case "extendable":
    case "mutable":
    case "const":
    case "map":
    case "sendport":
    case "raw sendport":
    case "js-object":
    case "function":
    case "capability":
    case "dart":
      return true;
    default:
      return false;
  }
}

/// Clones the message.
///
/// Contrary to a `_deserializeMessage(_serializeMessage(x))` the `_clone`
/// function will not try to adjust SendPort values and pass them through.
_clone(message) {
  _Serializer serializer = new _Serializer(serializeSendPorts: false);
  _Deserializer deserializer = new _Deserializer();
  return deserializer.deserialize(serializer.serialize(message));
}

class _Serializer {
  final bool _serializeSendPorts;
  Map<dynamic, int> serializedObjectIds = new Map<dynamic, int>.identity();

  _Serializer({serializeSendPorts: true})
      : _serializeSendPorts = serializeSendPorts;

  /// Returns a message that can be transmitted through web-worker channels.
  serialize(x) {
    if (_isPrimitive(x)) return serializePrimitive(x);

    int serializationId = serializedObjectIds[x];
    if (serializationId != null) return makeRef(serializationId);

    serializationId = serializedObjectIds.length;
    serializedObjectIds[x] = serializationId;

    if (x is NativeByteBuffer) return serializeByteBuffer(x);
    if (x is NativeTypedData) return serializeTypedData(x);
    if (x is JSIndexable) return serializeJSIndexable(x);
    if (x is InternalMap) return serializeMap(x as dynamic);

    if (x is JSObject) return serializeJSObject(x);

    // We should not have any interceptors any more.
    if (x is Interceptor) unsupported(x);

    if (x is RawReceivePort) {
      unsupported(x, "RawReceivePorts can't be transmitted:");
    }

    // SendPorts need their workerIds adjusted (either during serialization or
    // deserialization).
    if (x is _NativeJsSendPort) return serializeJsSendPort(x);
    if (x is _WorkerSendPort) return serializeWorkerSendPort(x);

    if (x is Closure) return serializeClosure(x);
    if (x is CapabilityImpl) return serializeCapability(x);

    return serializeDartObject(x);
  }

  void unsupported(x, [String message]) {
    if (message == null) message = "Can't transmit:";
    throw new UnsupportedError("$message $x");
  }

  makeRef(int serializationId) => ["ref", serializationId];

  serializePrimitive(primitive) => primitive;

  serializeByteBuffer(NativeByteBuffer buffer) {
    return ["buffer", buffer];
  }

  serializeTypedData(NativeTypedData data) {
    return ["typed", data];
  }

  serializeJSIndexable(JSIndexable indexable) {
    // Strings are JSIndexable but should have been treated earlier.
    assert(indexable is! String);
    List serialized = serializeArray(indexable);
    if (indexable is JSFixedArray) return ["fixed", serialized];
    if (indexable is JSExtendableArray) return ["extendable", serialized];
    // MutableArray check must be last, since JSFixedArray and JSExtendableArray
    // extend JSMutableArray.
    if (indexable is JSMutableArray) return ["mutable", serialized];
    // The only JSArrays left are the const Lists (as in `const [1, 2]`).
    if (indexable is JSArray) return ["const", serialized];
    unsupported(indexable, "Can't serialize indexable: ");
    return null;
  }

  serializeArray(JSArray x) {
    List serialized = [];
    serialized.length = x.length;
    for (int i = 0; i < x.length; i++) {
      serialized[i] = serialize(x[i]);
    }
    return serialized;
  }

  serializeArrayInPlace(JSArray x) {
    for (int i = 0; i < x.length; i++) {
      x[i] = serialize(x[i]);
    }
    return x;
  }

  serializeMap(Map x) {
    Function serializeTearOff = serialize;
    return [
      'map',
      x.keys.map(serializeTearOff).toList(),
      x.values.map(serializeTearOff).toList()
    ];
  }

  serializeJSObject(JSObject x) {
    // Don't serialize objects if their `constructor` property isn't `Object`
    // or undefined/null.
    // A different constructor is taken as a sign that the object has complex
    // internal state, or that it is a function, and won't be serialized.
    if (JS('bool', '!!(#.constructor)', x) &&
        JS('bool', 'x.constructor !== Object')) {
      unsupported(x, "Only plain JS Objects are supported:");
    }
    List keys = JS('JSArray', 'Object.keys(#)', x);
    List values = [];
    values.length = keys.length;
    for (int i = 0; i < keys.length; i++) {
      values[i] = serialize(JS('', '#[#]', x, keys[i]));
    }
    return ['js-object', keys, values];
  }

  serializeWorkerSendPort(_WorkerSendPort x) {
    if (_serializeSendPorts) {
      return ['sendport', x._workerId, x._isolateId, x._receivePortId];
    }
    return ['raw sendport', x];
  }

  serializeJsSendPort(_NativeJsSendPort x) {
    if (_serializeSendPorts) {
      int workerId = _globalState.currentManagerId;
      return ['sendport', workerId, x._isolateId, x._receivePort._id];
    }
    return ['raw sendport', x];
  }

  serializeCapability(CapabilityImpl x) => ['capability', x._id];

  serializeClosure(Closure x) {
    final name = IsolateNatives._getJSFunctionName(x);
    if (name == null) {
      unsupported(x, "Closures can't be transmitted:");
    }
    return ['function', name];
  }

  serializeDartObject(x) {
    if (!isDartObject(x)) unsupported(x);
    var classExtractor = JS_EMBEDDED_GLOBAL('', CLASS_ID_EXTRACTOR);
    var fieldsExtractor = JS_EMBEDDED_GLOBAL('', CLASS_FIELDS_EXTRACTOR);
    String classId = JS('String', '#(#)', classExtractor, x);
    List fields = JS('JSArray', '#(#)', fieldsExtractor, x);
    return ['dart', classId, serializeArrayInPlace(fields)];
  }
}

class _Deserializer {
  /// When `true`, encodes sendports specially so that they can be adjusted on
  /// the receiving end.
  ///
  /// When `false`, sendports are cloned like any other object.
  final bool _adjustSendPorts;

  List<dynamic> deserializedObjects = new List<dynamic>();

  _Deserializer({adjustSendPorts: true}) : _adjustSendPorts = adjustSendPorts;

  /// Returns a message that can be transmitted through web-worker channels.
  deserialize(x) {
    if (_isPrimitive(x)) return deserializePrimitive(x);

    if (x is! JSArray) throw new ArgumentError("Bad serialized message: $x");

    switch (x.first) {
      case "ref":
        return deserializeRef(x);
      case "buffer":
        return deserializeByteBuffer(x);
      case "typed":
        return deserializeTypedData(x);
      case "fixed":
        return deserializeFixed(x);
      case "extendable":
        return deserializeExtendable(x);
      case "mutable":
        return deserializeMutable(x);
      case "const":
        return deserializeConst(x);
      case "map":
        return deserializeMap(x);
      case "sendport":
        return deserializeSendPort(x);
      case "raw sendport":
        return deserializeRawSendPort(x);
      case "js-object":
        return deserializeJSObject(x);
      case "function":
        return deserializeClosure(x);
      case "capability":
        return deserializeCapability(x);
      case "dart":
        return deserializeDartObject(x);
      default:
        throw "couldn't deserialize: $x";
    }
  }

  deserializePrimitive(x) => x;

  // ['ref', id].
  deserializeRef(x) {
    assert(x[0] == 'ref');
    int serializationId = x[1];
    return deserializedObjects[serializationId];
  }

  // ['buffer', <byte buffer>].
  NativeByteBuffer deserializeByteBuffer(x) {
    assert(x[0] == 'buffer');
    NativeByteBuffer result = x[1];
    deserializedObjects.add(result);
    return result;
  }

  // ['typed', <typed array>].
  NativeTypedData deserializeTypedData(x) {
    assert(x[0] == 'typed');
    NativeTypedData result = x[1];
    deserializedObjects.add(result);
    return result;
  }

  // Updates the given array in place with its deserialized content.
  List deserializeArrayInPlace(JSArray x) {
    for (int i = 0; i < x.length; i++) {
      x[i] = deserialize(x[i]);
    }
    return x;
  }

  // ['fixed', <array>].
  List deserializeFixed(x) {
    assert(x[0] == 'fixed');
    List result = x[1];
    deserializedObjects.add(result);
    return new JSArray.markFixed(deserializeArrayInPlace(result));
  }

  // ['extendable', <array>].
  List deserializeExtendable(x) {
    assert(x[0] == 'extendable');
    List result = x[1];
    deserializedObjects.add(result);
    return new JSArray.markGrowable(deserializeArrayInPlace(result));
  }

  // ['mutable', <array>].
  List deserializeMutable(x) {
    assert(x[0] == 'mutable');
    List result = x[1];
    deserializedObjects.add(result);
    return deserializeArrayInPlace(result);
  }

  // ['const', <array>].
  List deserializeConst(x) {
    assert(x[0] == 'const');
    List result = x[1];
    deserializedObjects.add(result);
    // TODO(floitsch): need to mark list as non-changeable.
    return new JSArray.markFixed(deserializeArrayInPlace(result));
  }

  // ['map', <key-list>, <value-list>].
  Map deserializeMap(x) {
    assert(x[0] == 'map');
    List keys = x[1];
    List values = x[2];
    Map result = {};
    deserializedObjects.add(result);
    // We need to keep the order of how objects were serialized.
    // First deserialize all keys, and then only deserialize the values.
    keys = keys.map(deserialize).toList();

    for (int i = 0; i < keys.length; i++) {
      result[keys[i]] = deserialize(values[i]);
    }
    return result;
  }

  // ['sendport', <managerId>, <isolateId>, <receivePortId>].
  SendPort deserializeSendPort(x) {
    assert(x[0] == 'sendport');
    int managerId = x[1];
    int isolateId = x[2];
    int receivePortId = x[3];
    SendPort result;
    // If two isolates are in the same manager, we use NativeJsSendPorts to
    // deliver messages directly without using postMessage.
    if (managerId == _globalState.currentManagerId) {
      var isolate = _globalState.isolates[isolateId];
      if (isolate == null) return null; // Isolate has been closed.
      var receivePort = isolate.lookup(receivePortId);
      if (receivePort == null) return null; // Port has been closed.
      result = new _NativeJsSendPort(receivePort, isolateId);
    } else {
      result = new _WorkerSendPort(managerId, isolateId, receivePortId);
    }
    deserializedObjects.add(result);
    return result;
  }

  // ['raw sendport', <sendport>].
  SendPort deserializeRawSendPort(x) {
    assert(x[0] == 'raw sendport');
    SendPort result = x[1];
    deserializedObjects.add(result);
    return result;
  }

  // ['js-object', <key-list>, <value-list>].
  deserializeJSObject(x) {
    assert(x[0] == 'js-object');
    List keys = x[1];
    List values = x[2];
    var o = JS('', '{}');
    deserializedObjects.add(o);
    for (int i = 0; i < keys.length; i++) {
      JS('', '#[#]=#', o, keys[i], deserialize(values[i]));
    }
    return o;
  }

  // ['function', <name>].
  Function deserializeClosure(x) {
    assert(x[0] == 'function');
    String name = x[1];
    Function result = IsolateNatives._getJSFunctionFromName(name);
    deserializedObjects.add(result);
    return result;
  }

  // ['capability', <id>].
  Capability deserializeCapability(x) {
    assert(x[0] == 'capability');
    return new CapabilityImpl._internal(x[1]);
  }

  // ['dart', <class-id>, <field-list>].
  deserializeDartObject(x) {
    assert(x[0] == 'dart');
    String classId = x[1];
    List fields = x[2];
    var instanceFromClassId = JS_EMBEDDED_GLOBAL('', INSTANCE_FROM_CLASS_ID);
    var initializeObject = JS_EMBEDDED_GLOBAL('', INITIALIZE_EMPTY_INSTANCE);

    var emptyInstance = JS('', '#(#)', instanceFromClassId, classId);
    deserializedObjects.add(emptyInstance);
    deserializeArrayInPlace(fields);
    return JS(
        '', '#(#, #, #)', initializeObject, classId, emptyInstance, fields);
  }
}

bool _isPrimitive(x) => x == null || x is String || x is num || x is bool;
