// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const int FILE_EXISTS = 0;
const int FILE_CREATE = 1;
const int FILE_DELETE = 2;
const int FILE_RENAME = 3;
const int FILE_OPEN = 4;
const int FILE_RESOLVE_SYMBOLIC_LINKS = 5;
const int FILE_CLOSE = 6;
const int FILE_POSITION = 7;
const int FILE_SET_POSITION = 8;
const int FILE_TRUNCATE = 9;
const int FILE_LENGTH = 10;
const int FILE_LENGTH_FROM_PATH = 11;
const int FILE_LAST_MODIFIED = 12;
const int FILE_FLUSH = 13;
const int FILE_READ_BYTE = 14;
const int FILE_WRITE_BYTE = 15;
const int FILE_READ = 16;
const int FILE_READ_INTO = 17;
const int FILE_WRITE_FROM = 18;
const int FILE_CREATE_LINK = 19;
const int FILE_DELETE_LINK = 20;
const int FILE_RENAME_LINK = 21;
const int FILE_LINK_TARGET = 22;
const int FILE_TYPE = 23;
const int FILE_IDENTICAL = 24;
const int FILE_STAT = 25;
const int SOCKET_LOOKUP = 26;
const int SOCKET_LIST_INTERFACES = 27;
const int SOCKET_REVERSE_LOOKUP = 28;
const int DIRECTORY_CREATE = 29;
const int DIRECTORY_DELETE = 30;
const int DIRECTORY_EXISTS = 31;
const int DIRECTORY_CREATE_TEMP = 32;
const int DIRECTORY_LIST_START = 33;
const int DIRECTORY_LIST_NEXT = 34;
const int DIRECTORY_LIST_STOP = 35;
const int DIRECTORY_RENAME = 36;
const int SSL_PROCESS_FILTER = 37;

class IOService {
  // Lazy initialize service ports, 32 per isolate.
  static const int _SERVICE_PORT_COUNT = 32;
  static List<SendPort> _servicePort = new List(_SERVICE_PORT_COUNT);
  static ReceivePort _receivePort;
  static SendPort _replyToPort;
  static Map<int, Completer> _messageMap = {};
  static int _id = 0;

  static Future dispatch(int request, List data) {
    int id;
    do {
      id = _getNextId();
    } while (_messageMap.containsKey(id));
    int index = id % _SERVICE_PORT_COUNT;
    _initialize(index);
    var completer = new Completer();
    _messageMap[id] = completer;
    _servicePort[index].send([id, request, data], _replyToPort);
    return completer.future;
  }

  static void _initialize(int index) {
    if (_servicePort[index] == null) {
      _servicePort[index] = _newServicePort();
    }
    if (_receivePort == null) {
      _receivePort = new ReceivePort();
      _replyToPort = _receivePort.toSendPort();
      _receivePort.receive((data, _) {
        assert(data is List && data.length == 2);
        _messageMap.remove(data[0]).complete(data[1]);
        if (_messageMap.length == 0) {
          _id = 0;
          _receivePort.close();
          _receivePort = null;
        }
      });
    }
  }

  static int _getNextId() {
    if (_id == 0x7FFFFFFF) _id = 0;
    return _id++;
  }

  static SendPort _newServicePort() native "IOService_NewServicePort";
}
