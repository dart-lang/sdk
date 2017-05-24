// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _IOServicePorts {
  List<SendPort> _freeServicePorts = <SendPort>[];
  HashMap<int, SendPort> _usedBy = new HashMap<int, SendPort>();

  _IOServicePorts();

  SendPort _getFreePort(int forRequestId) {
    if (_freeServicePorts.isEmpty) {
      _freeServicePorts.add(_newServicePort());
    }
    SendPort freePort = _freeServicePorts.removeLast();
    assert(!_usedBy.containsKey(forRequestId));
    _usedBy[forRequestId] = freePort;
    return freePort;
  }

  void _returnPort(int forRequestId) {
    _freeServicePorts.add(_usedBy.remove(forRequestId));
  }

  static SendPort _newServicePort() native "IOService_NewServicePort";
}

@patch
class _IOService {
  static _IOServicePorts _servicePorts = new _IOServicePorts();
  static RawReceivePort _receivePort;
  static SendPort _replyToPort;
  static HashMap<int, Completer> _messageMap = new HashMap<int, Completer>();
  static int _id = 0;

  @patch
  static Future _dispatch(int request, List data) {
    int id;
    do {
      id = _getNextId();
    } while (_messageMap.containsKey(id));
    SendPort servicePort = _servicePorts._getFreePort(id);
    _ensureInitialize();
    var completer = new Completer();
    _messageMap[id] = completer;
    try {
      servicePort.send([id, _replyToPort, request, data]);
    } catch (error) {
      _messageMap.remove(id).complete(error);
      if (_messageMap.length == 0) {
        _finalize();
      }
    }
    return completer.future;
  }

  static void _ensureInitialize() {
    if (_receivePort == null) {
      _receivePort = new RawReceivePort();
      _replyToPort = _receivePort.sendPort;
      _receivePort.handler = (data) {
        assert(data is List && data.length == 2);
        _messageMap.remove(data[0]).complete(data[1]);
        _servicePorts._returnPort(data[0]);
        if (_messageMap.length == 0) {
          _finalize();
        }
      };
    }
  }

  static void _finalize() {
    _id = 0;
    _receivePort.close();
    _receivePort = null;
  }

  static int _getNextId() {
    if (_id == 0x7FFFFFFF) _id = 0;
    return _id++;
  }
}
