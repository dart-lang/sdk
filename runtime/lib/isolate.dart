// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _ReceivePortFactory {
  factory ReceivePort() {
    return new _ReceivePortImpl();
  }
}


class _ReceivePortImpl implements ReceivePort {
  /*--- public interface ---*/
  factory _ReceivePortImpl() native "ReceivePortImpl_factory";

  receive(void onMessage(var message, SendPort replyTo)) {
    _onMessage = onMessage;
  }

  close() {
    _portMap.remove(_id);
    _closeInternal(_id);
  }

  SendPort toSendPort() {
    return new _SendPortImpl(_id);
  }

  /**** Internal implementation details ****/
  // Called from the VM to create a new ReceivePort instance.
  static _ReceivePortImpl _get_or_create(int id) {
    if (_portMap !== null) {
      _ReceivePortImpl port = _portMap[id];
      if (port !== null) {
        return port;
      }
    }
    return new _ReceivePortImpl._internal(id);
  }
  _ReceivePortImpl._internal(int id) : _id = id {
    if (_portMap === null) {
      _portMap = new Map();
    }
    _portMap[id] = this;
  }

  // Called from the VM to dispatch to the handler.
  static void _handleMessage(int id, int replyId, var message) {
    assert(_portMap !== null);
    ReceivePort port = _portMap[id];
    SendPort replyTo = (replyId == 0) ? null : new _SendPortImpl(replyId);
    (port._onMessage)(message, replyTo);
  }

  // Call into the VM to close the VM maintained mappings.
  static _closeInternal(int id) native "ReceivePortImpl_closeInternal";

  final int _id;
  var _onMessage;

  // id to ReceivePort mapping.
  static Map _portMap;
}


class _SendPortImpl implements SendPort {
  /*--- public interface ---*/
  void send(var message, [SendPort replyTo = null]) {
    this._sendNow(message, replyTo);
  }

  void _sendNow(var message, SendPort replyTo) {
    int replyId = (replyTo === null) ? 0 : replyTo._id;
    _sendInternal(_id, replyId, message);
  }

  Future call(var message) {
    final completer = new Completer();
    final port = new _ReceivePortImpl();
    send(message, port.toSendPort());
    port.receive((value, ignoreReplyTo) {
      port.close();
      if (value is Exception) {
        completer.completeException(value);
      } else {
        completer.complete(value);
      }
    });
    return completer.future;
  }

  bool operator==(var other) {
    return (other is _SendPortImpl) && _id == other._id;
  }

  int hashCode() {
    return _id;
  }

  /*--- private implementation ---*/
  const _SendPortImpl(int id) : _id = id;

  // _SendPortImpl._create is called from the VM when a new SendPort instance is
  // needed by the VM code.
  static SendPort _create(int id) {
    return new _SendPortImpl(id);
  }

  // Forward the implementation of sending messages to the VM. Only port ids
  // are being handed to the VM.
  static _sendInternal(int sendId, int replyId, var message)
      native "SendPortImpl_sendInternal_";

  final int _id;
}

class _IsolateNatives {
  static Future<SendPort> spawn(Isolate isolate, bool isLight) {
    Completer<SendPort> completer = new Completer<SendPort>();
    SendPort port = _start(isolate, isLight);
    completer.complete(port);
    return completer.future;
  }

  // Starts a new isolate calling the run method on a new instance of the
  // remote class's type.
  // Returns the send port which is passed to the newly created isolate.
  // This method is being dispatched to from the public core library code.
  static SendPort _start(Isolate isolate, bool light)
      native "IsolateNatives_start";
}

_getPortInternal() native "isolate_getPortInternal";

ReceivePort _portInternal;

ReceivePort get _port() {
  if (_portInternal === null) {
    _portInternal = _getPortInternal();
  }
  return _portInternal;
}

_spawnFunction(void topLevelFunction()) native "isolate_spawnFunction";

_spawnUri(String uri) native "isolate_spawnUri";
