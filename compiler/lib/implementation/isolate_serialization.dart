// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MessageTraverser {
  static bool isPrimitive(x) {
    return (x === null) || (x is String) || (x is num) || (x is bool);
  }

  MessageTraverser();

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

  void _cleanup() {
    int len = _taggedObjects.length;
    for (int i = 0; i < len; i++) {
      _clearAttachedInfo(_taggedObjects[i]);
    }
    _taggedObjects = null;
  }

  void _attachInfo(var o, var info) {
    _taggedObjects.add(o);
    _setAttachedInfo(o, info);
  }

  _getInfo(var o) {
    return _getAttachedInfo(o);
  }

  _dispatch(var x) {
    if (isPrimitive(x)) return visitPrimitive(x);
    if (x is List) return visitList(x);
    if (x is Map) return visitMap(x);
    if (x is SendPortImpl) return visitSendPort(x);
    if (x is ReceivePortImpl) return visitReceivePort(x);
    if (x is ReceivePortSingleShotImpl) return visitReceivePortSingleShot(x);
    // TODO(floitsch): make this a real exception. (which one)?
    throw "Message serialization: Illegal value $x passed";
  }

  abstract visitPrimitive(x);
  abstract visitList(List x);
  abstract visitMap(Map x);
  abstract visitSendPort(SendPortImpl x);
  abstract visitReceivePort(ReceivePortImpl x);
  abstract visitReceivePortSingleShot(ReceivePortSingleShotImpl x);

  List _taggedObjects;

  _clearAttachedInfo(var obj) native;
  _setAttachedInfo(var o, var info) native;
  _getAttachedInfo(var o) native;
}

class Copier extends MessageTraverser {
  Copier() : super();

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

  SendPort visitSendPort(SendPortImpl port) {
    return new SendPortImpl(port._workerId,
                            port._isolateId,
                            port._receivePortId);
  }

  SendPort visitReceivePort(ReceivePortImpl port) {
    return port._toNewSendPort();
  }

  SendPort visitReceivePortSingleShot(ReceivePortSingleShotImpl port) {
    return port._toNewSendPort();
  }
}

class Serializer extends MessageTraverser {
  Serializer() : super();

  visitPrimitive(x) => x;

  visitList(List list) {
    int copyId = _getInfo(list);
    if (copyId !== null) return _makeRef(copyId);

    int id = _nextFreeRefId++;
    _attachInfo(list, id);
    var jsArray = _serializeDartListIntoNewJsArray(list);
    // TODO(floitsch): we are losing the generic type.
    return _dartListToJsArrayNoCopy(['list', id, jsArray]);
  }

  visitMap(Map map) {
    int copyId = _getInfo(map);
    if (copyId !== null) return _makeRef(copyId);

    int id = _nextFreeRefId++;
    _attachInfo(map, id);
    var keys = _serializeDartListIntoNewJsArray(map.getKeys());
    var values = _serializeDartListIntoNewJsArray(map.getValues());
    // TODO(floitsch): we are losing the generic type.
    return _dartListToJsArrayNoCopy(['map', id, keys, values]);
  }

  visitSendPort(SendPortImpl port) {
    return _dartListToJsArrayNoCopy(['sendport',
                                     port._workerId,
                                     port._isolateId,
                                     port._receivePortId]);
  }

  visitReceivePort(ReceivePortImpl port) {
    return visitSendPort(port.toSendPort());;
  }

  visitReceivePortSingleShot(ReceivePortSingleShotImpl port) {
    return visitSendPort(port.toSendPort());
  }

  _serializeDartListIntoNewJsArray(List list) {
    int len = list.length;
    var jsArray = _newJsArray(len);
    for (int i = 0; i < len; i++) {
      _jsArrayIndexSet(jsArray, i, _dispatch(list[i]));
    }
    return jsArray;
  }

  _makeRef(int id) {
    return _dartListToJsArrayNoCopy(['ref', id]);
  }

  int _nextFreeRefId = 0;

  static _newJsArray(int len) native;
  static _jsArrayIndexSet(jsArray, int index, val) native;
  static _dartListToJsArrayNoCopy(List list) native;
}

class Deserializer {
  Deserializer();

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
    assert(_isJsArray(x));
    switch (_jsArrayIndex(x, 0)) {
      case 'ref': return _deserializeRef(x);
      case 'list': return _deserializeList(x);
      case 'map': return _deserializeMap(x);
      case 'sendport': return _deserializeSendPort(x);
      // TODO(floitsch): Use real exception (which one?).
      default: throw "Unexpected serialized object";
    }
  }

  _deserializeRef(x) {
    int id = _jsArrayIndex(x, 1);
    var result = _deserialized[id];
    assert(result !== null);
    return result;
  }

  List _deserializeList(x) {
    int id = _jsArrayIndex(x, 1);
    var jsArray = _jsArrayIndex(x, 2);
    assert(_isJsArray(jsArray));
    List dartList = _jsArrayToDartListNoCopy(jsArray);
    _deserialized[id] = dartList;
    int len = dartList.length;
    for (int i = 0; i < len; i++) {
      dartList[i] = _deserializeHelper(dartList[i]);
    }
    return dartList;
  }

  Map _deserializeMap(x) {
    Map result = new Map();
    int id = _jsArrayIndex(x, 1);
    _deserialized[id] = result;
    var keys = _jsArrayIndex(x, 2);
    var values = _jsArrayIndex(x, 3);
    assert(_isJsArray(keys));
    assert(_isJsArray(values));
    int len = _jsArrayLength(keys);
    assert(len == _jsArrayLength(values));
    for (int i = 0; i < len; i++) {
      var key = _deserializeHelper(_jsArrayIndex(keys, i));
      var value = _deserializeHelper(_jsArrayIndex(values, i));
      result[key] = value;
    }
    return result;
  }

  SendPort _deserializeSendPort(x) {
    int workerId = _jsArrayIndex(x, 1);
    int isolateId = _jsArrayIndex(x, 2);
    int receivePortId = _jsArrayIndex(x, 3);
    return new SendPortImpl(workerId, isolateId, receivePortId);
  }

  List _jsArrayToDartListNoCopy(a) {
    // We rely on the fact that Dart-lists are directly mapped to Js-arrays.
    // TODO(floitsch): can we do better here?
    assert(a is List);
    return a;
  }

  // TODO(floitsch): this should by Map<int, var> or Map<int, Dynamic>.
  Map _deserialized;

  static bool _isJsArray(x) native;
  static _jsArrayIndex(x, int index) native;
  static int _jsArrayLength(x) native;
}
