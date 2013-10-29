// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _IOService {
  // Lazy initialize service ports, 32 per isolate.
  static const int _SERVICE_PORT_COUNT = 32;
  static List<SendPort> _servicePort = new List(_SERVICE_PORT_COUNT);
  static RawReceivePort _receivePort;
  static SendPort _replyToPort;
  static Map<int, Completer> _messageMap = {};
  static int _id = 0;

  /* patch */ static Future dispatch(int request, List data) {
    int id;
    do {
      id = _getNextId();
    } while (_messageMap.containsKey(id));
    int index = id % _SERVICE_PORT_COUNT;
    _initialize(index);
    var completer = new Completer();
    _messageMap[id] = completer;
    _servicePort[index].send([id, _replyToPort, request, data]);
    return completer.future;
  }

  static void _initialize(int index) {
    if (_servicePort[index] == null) {
      _servicePort[index] = _newServicePort();
    }
    if (_receivePort == null) {
      _receivePort = new RawReceivePort();
      _replyToPort = _receivePort.sendPort;
      _receivePort.handler = (data) {
        assert(data is List && data.length == 2);
        _messageMap.remove(data[0]).complete(data[1]);
        if (_messageMap.length == 0) {
          _id = 0;
          _receivePort.close();
          _receivePort = null;
        }
      };
    }
  }

  static int _getNextId() {
    if (_id == 0x7FFFFFFF) _id = 0;
    return _id++;
  }

  static SendPort _newServicePort() native "IOService_NewServicePort";
}
