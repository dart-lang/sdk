// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

_serialize(var message) {
  return new _JsSerializer().traverse(message);
}

class JsProxy {
  SendPortSync _port;
  final _id;

  JsProxy._internal(this._port, this._id);

  noSuchMethod(method, args) {
    var result = _port.callSync([_id, method, args]);
    switch (result[0]) {
      case 'return': return result[1];
      case 'exception': throw result[1];
      case 'none': throw new NoSuchMethodException(this, method, args);
      default: throw 'Invalid return value';
    }
  }
}

int _localNextElementId = 0;

const _DART_ID = 'data-dart_id';

var _elementId(Element e) {
  if (e.attributes.containsKey(_DART_ID)) return e.attributes[_DART_ID];
  var id = '$_isolateId-${_localNextElementId++}';
  e.attributes[_DART_ID] = id;
  return id;
}

Element _getElement(var id) {
  var list = queryAll('[$_DART_ID="$id"]');
  if (list.length > 1) throw 'Non unique ID: $id';
  if (list.length == 0) {
    throw 'Only elements attached to document can be serialized: $id';
  }
  return list[0];
}

class _JsSerializer extends _Serializer {

  visitSendPortSync(SendPortSync x) {
    if (x is _JsSendPortSync) return visitJsSendPortSync(x);
    if (x is _LocalSendPortSync) return visitLocalSendPortSync(x);
    if (x is _RemoteSendPortSync) return visitRemoteSendPortSync(x);
    throw "Unknown port type $x";
  }

  visitJsSendPortSync(_JsSendPortSync x) {
    return [ 'sendport', 'nativejs', x._id ];
  }

  visitLocalSendPortSync(_LocalSendPortSync x) {
    return [ 'sendport', 'dart',
             ReceivePortSync._isolateId, x._receivePort._portId ];
  }

  visitRemoteSendPortSync(_RemoteSendPortSync x) {
    return [ 'sendport', 'dart',
             x._receivePort._isolateId, x._receivePort._portId ];
  }

  visitObject(Object x) {
    if (x is Function) return visitFunction(x);
    if (x is JsProxy) return visitJsProxy(x);
    if (x is Element) return visitElement(x);

    // TODO: Handle DOM elements and proxy other objects.
    var proxyId = _dartProxyRegistry._add(x);
    return [ 'objref', proxyId,
             visitSendPortSync(_dartProxyRegistry._sendPort) ];
 }

  visitFunction(Function func) {
    return [ 'funcref',
             _functionRegistry._add(func),
             visitSendPortSync(_functionRegistry._sendPort), null ];
  }

  visitJsProxy(JsProxy proxy) {
    return [ 'objref', proxy._id, visitSendPortSync(proxy._port) ];
  }

  visitElement(Element element) {
    var id = _elementId(element);
    // Verify that the element is connected to the document.
    // Otherwise, we will not be able to find it on the other side.
    _getElement(id);
    return [ 'element', id ];
  }
}

// Leaking implementation.  Later will be backend specific and hopefully
// not leaking (at least in most of the cases.)
// TODO: provide better, backend specific implementation.
class _Registry<T> {
  final String _name;
  int _nextId;
  final Map<String, T> _registry;
  final ReceivePortSync _port;

  _Registry(this._name) :
      _nextId = 0,
      _registry = <T>{},
      _port = new ReceivePortSync();

  String _add(T x) {
    // TODO(vsm): Cache x and reuse id.
    final id = '$_name-${_nextId++}';
    _registry[id] = x;
    return id;
  }

  T _get(String id) {
    return _registry[id];
  }

  get _sendPort => _port.toSendPort();
}

class _FunctionRegistry extends _Registry<Function> {
  _FunctionRegistry() : super('func-ref') {
    _port.receive((msg) {
      final id = msg[0];
      final args = msg[1];
      final f = _registry[id];
      switch (args.length) {
        case 0: return f();
        case 1: return f(args[0]);
        case 2: return f(args[0], args[1]);
        case 3: return f(args[0], args[1], args[2]);
        case 4: return f(args[0], args[1], args[2], args[3]);
        default: throw 'Unsupported number of arguments.';
      }
    });
  }
}

_FunctionRegistry __functionRegistry;
get _functionRegistry {
  if (__functionRegistry === null) __functionRegistry = new _FunctionRegistry();
  return __functionRegistry;
}
/// End of function serialization implementation.

/// Object proxy implementation.

class _DartProxyRegistry extends _Registry<Object> {
  _DartProxyRegistry() : super('dart-ref') {
    _port.receive((msg) {
      // TODO(vsm): Support a mechanism to register a handler here.
      throw 'Invocation unsupported on Dart proxies';
    });
  }
}

_DartProxyRegistry __dartProxyRegistry;
get _dartProxyRegistry {
  if (__dartProxyRegistry === null) {
    __dartProxyRegistry = new _DartProxyRegistry();
  }
  return __dartProxyRegistry;
}

/// End of object proxy implementation.

_deserialize(var message) {
  return new _JsDeserializer().deserialize(message);
}

class _JsDeserializer extends _Deserializer {

  static final _UNSPECIFIED = const Object();

  deserializeSendPort(List x) {
    String tag = x[1];
    switch (tag) {
      case 'nativejs':
        num id = x[2];
        return new _JsSendPortSync(id);
      case 'dart':
        num isolateId = x[2];
        num portId = x[3];
        return ReceivePortSync._lookup(isolateId, portId);
      default:
        throw 'Illegal SendPortSync type: $tag';
    }
  }

  deserializeObject(List x) {
    String tag = x[0];
    switch (tag) {
      case 'funcref': return deserializeFunction(x);
      case 'objref': return deserializeProxy(x);
      case 'element': return deserializeElement(x);
      default: throw 'Illegal object type: $x';
    }
  }

  deserializeFunction(List x) {
    var id = x[1];
    SendPortSync port = deserializeSendPort(x[2]);
    // TODO: Support varargs when there is support in the language.
    return ([arg0 = _UNSPECIFIED, arg1 = _UNSPECIFIED,
              arg2 = _UNSPECIFIED, arg3 = _UNSPECIFIED]) {
      var args = [arg0, arg1, arg2, arg3];
      var last = args.indexOf(_UNSPECIFIED);
      if (last >= 0) args = args.getRange(0, last);
      var message = [id, args];
      return port.callSync(message);
    };
  }

  deserializeProxy(x) {
    var id = x[1];
    var port = deserializeSendPort(x[2]);
    if (port is _JsSendPortSync) return new JsProxy._internal(port, id);
    if (port is _LocalSendPortSync) return _dartProxyRegistry._get(id);
    // TODO(vsm): Support this case.
    if (port is _RemoteSendPortSync) throw 'Remote Dart proxies unsupported';
    throw 'Illegal proxy: $port';
  }

  deserializeElement(x) {
    var id = x[1];
    return _getElement(id);
  }
}

// The receiver is JS.
class _JsSendPortSync implements SendPortSync {

  num _id;
  _JsSendPortSync(this._id);

  callSync(var message) {
    var serialized = _serialize(message);
    var result = _callPortSync(_id, serialized);
    return _deserialize(result);
  }

}

// TODO(vsm): Differentiate between Dart2Js and Dartium isolates.
// The receiver is a different Dart isolate, compiled to JS.
class _RemoteSendPortSync implements SendPortSync {

  int _isolateId;
  int _portId;
  _RemoteSendPortSync(this._isolateId, this._portId);

  callSync(var message) {
    var serialized = _serialize(message);
    var result = _call(_isolateId, _portId, serialized);
    return _deserialize(result);
  }

  static _call(int isolateId, int portId, var message) {
    var target = 'dart-port-$isolateId-$portId'; 
    // TODO(vsm): Make this re-entrant.
    // TODO(vsm): Set this up set once, on the first call.
    var source = '$target-result';
    var result = null;
    var listener = (TextEvent e) {
      result = JSON.parse(e.data);
    };
    window.on[source].add(listener);
    _dispatchEvent(target, [source, message]);
    window.on[source].remove(listener);
    return result;
  }
}

// The receiver is in the same Dart isolate, compiled to JS.
class _LocalSendPortSync implements SendPortSync {

  ReceivePortSync _receivePort;

  _LocalSendPortSync._internal(this._receivePort);

  callSync(var message) {
    // TODO(vsm): Do a more efficient deep copy.
    var copy = _deserialize(_serialize(message));
    var result = _receivePort._callback(copy);
    return _deserialize(_serialize(result));
  }
}

// TODO(vsm): Move this to dart:isolate.  This will take some
// refactoring as there are dependences here on the DOM.  Users
// interact with this class (or interface if we change it) directly -
// new ReceivePortSync.  I think most of the DOM logic could be
// delayed until the corresponding SendPort is registered on the
// window.

// A Dart ReceivePortSync (tagged 'dart' when serialized) is
// identifiable / resolvable by the combination of its isolateid and
// portid.  When a corresponding SendPort is used within the same
// isolate, the _portMap below can be used to obtain the
// ReceivePortSync directly.  Across isolates (or from JS), an
// EventListener can be used to communicate with the port indirectly.
class ReceivePortSync {

  static Map<int, ReceivePortSync> _portMap;
  static int _portIdCount;
  static int _cachedIsolateId;

  num _portId;
  Function _callback;
  EventListener _listener;

  ReceivePortSync() {
    if (_portIdCount == null) {
      _portIdCount = 0;
      _portMap = new Map<int, ReceivePortSync>();
    }
    _portId = _portIdCount++;
    _portMap[_portId] = this;
  }

  static int get _isolateId {
    // TODO(vsm): Make this coherent with existing isolate code.
    if (_cachedIsolateId == null) {
      _cachedIsolateId = _getNewIsolateId();      
    }
    return _cachedIsolateId;
  }

  static String _getListenerName(isolateId, portId) =>
      'dart-port-$isolateId-$portId'; 
  String get _listenerName => _getListenerName(_isolateId, _portId);

  void receive(callback(var message)) {
    _callback = callback;
    if (_listener === null) {
      _listener = (TextEvent e) {
        var data = JSON.parse(e.data);
        var replyTo = data[0];
        var message = _deserialize(data[1]);
        var result = _callback(message);
        _dispatchEvent(replyTo, _serialize(result));
      };
      window.on[_listenerName].add(_listener);
    }
  }

  void close() {
    _portMap.remove(_portId);
    if (_listener !== null) window.on[_listenerName].remove(_listener);
  }

  SendPortSync toSendPort() {
    return new _LocalSendPortSync._internal(this);
  }

  static SendPortSync _lookup(int isolateId, int portId) {
    if (isolateId == _isolateId) {
      return _portMap[portId].toSendPort();
    } else {
      return new _RemoteSendPortSync(isolateId, portId);
    }
  }
}

get _isolateId => ReceivePortSync._isolateId;

void _dispatchEvent(String receiver, var message) {
  var event = document.$dom_createEvent('TextEvent');
  event.initTextEvent(receiver, false, false, window, JSON.stringify(message));
  window.$dom_dispatchEvent(event);
}
