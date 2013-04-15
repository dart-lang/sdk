// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _CloseToken {
  /// This token is sent from [IsolateSink]s to [IsolateStream]s to ask them to
  /// close themselves.
  const _CloseToken();
}

patch bool _isCloseToken(var object) {
  // TODO(floitsch): can we compare against const _CloseToken()?
  return object is _CloseToken;
}

patch class MessageBox {
  /* patch */ MessageBox.oneShot() : this._oneShot(new ReceivePort());
  MessageBox._oneShot(ReceivePort receivePort)
      : stream = new IsolateStream._fromOriginalReceivePortOneShot(receivePort),
        sink = new _IsolateSink._fromPort(receivePort.toSendPort());

  /* patch */ MessageBox() : this._(new ReceivePort());
  MessageBox._(ReceivePort receivePort)
      : stream = new IsolateStream._fromOriginalReceivePort(receivePort),
        sink = new _IsolateSink._fromPort(receivePort.toSendPort());
}

class _IsolateSink implements IsolateSink {
  bool _isClosed = false;
  final SendPort _port;
  _IsolateSink._fromPort(this._port);

  void add(dynamic message) {
    _port.send(message);
  }

  void addError(Object errorEvent) {
    throw new UnimplementedError("addError on isolate streams");
  }

  void close() {
    if (_isClosed) return;
    add(const _CloseToken());
    _isClosed = true;
  }

  bool operator==(var other) {
    return other is IsolateSink && _port == other._port;
  }

  int get hashCode => _port.hashCode + 499;
}

patch IsolateSink streamSpawnFunction(
    void topLevelFunction(),
    [bool unhandledExceptionCallback(IsolateUnhandledException e)]) {
  SendPort sendPort = spawnFunction(topLevelFunction,
                                    unhandledExceptionCallback);
  return new _IsolateSink._fromPort(sendPort);
}

patch class ReceivePort {
  /* patch */ factory ReceivePort() {
    return new _ReceivePortImpl();
  }
}

class _ReceivePortImpl implements ReceivePort {
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
    if (_portMap != null) {
      _ReceivePortImpl port = _portMap[id];
      if (port != null) {
        return port;
      }
    }
    return new _ReceivePortImpl._internal(id);
  }

  _ReceivePortImpl._internal(int id) : _id = id {
    if (_portMap == null) {
      _portMap = new Map();
    }
    _portMap[id] = this;
  }

  // Called from the VM to retrieve the ReceivePort for a message.
  static _ReceivePortImpl _lookupReceivePort(int id) {
    assert(_portMap != null);
    return _portMap[id];
  }

  // Called from the VM to dispatch to the handler.
  static void _handleMessage(_ReceivePortImpl port, int replyId, var message) {
    assert(port != null);
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
    int replyId = (replyTo == null) ? 0 : replyTo._id;
    _sendInternal(_id, replyId, message);
  }

  Future call(var message) {
    final completer = new Completer();
    final port = new _ReceivePortImpl();
    send(message, port.toSendPort());
    port.receive((value, ignoreReplyTo) {
      port.close();
      if (value is Exception) {
        completer.completeError(value);
      } else {
        completer.complete(value);
      }
    });
    return completer.future;
  }

  bool operator==(var other) {
    return (other is _SendPortImpl) && _id == other._id;
  }

  int get hashCode {
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

_getPortInternal() native "isolate_getPortInternal";

ReceivePort _portInternal;

patch class _Isolate {
  /* patch */ static ReceivePort get port {
    if (_portInternal == null) {
      _portInternal = _getPortInternal();
    }
    return _portInternal;
  }

  /* patch */ static spawnFunction(void topLevelFunction(),
      [bool unhandledExceptionCallback(IsolateUnhandledException e)])
      native "isolate_spawnFunction";

  /* patch */ static spawnUri(String uri) native "isolate_spawnUri";
}
