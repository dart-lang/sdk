// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _IOServicePorts {
  // We limit the number of IO Service ports per isolate so that we don't
  // spawn too many threads all at once, which can crash the VM on Windows.
  static const int maxPorts = 32;
  List<SendPort> _ports = <SendPort>[];
  List<SendPort> _freePorts = <SendPort>[];
  HashMap<int, SendPort> _usedPorts = new HashMap<int, SendPort>();

  _IOServicePorts();

  SendPort _getPort(int forRequestId) {
    if (_freePorts.isEmpty && _usedPorts.length < maxPorts) {
      final SendPort port = _newServicePort();
      _ports.add(port);
      _freePorts.add(port);
    }
    if (!_freePorts.isEmpty) {
      final SendPort port = _freePorts.removeLast();
      assert(!_usedPorts.containsKey(forRequestId));
      _usedPorts[forRequestId] = port;
      return port;
    }
    // We have already allocated the max number of ports. Re-use an
    // existing one.
    final SendPort port = _ports[forRequestId % maxPorts];
    _usedPorts[forRequestId] = port;
    return port;
  }

  void _returnPort(int forRequestId) {
    final SendPort port = _usedPorts.remove(forRequestId);
    if (!_usedPorts.values.contains(port)) {
      _freePorts.add(port);
    }
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
    final SendPort servicePort = _servicePorts._getPort(id);
    _ensureInitialize();
    final Completer completer = new Completer();
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
