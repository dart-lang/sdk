// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

@pragma("vm:external-name", "IOService_NewServicePort")
external SendPort _newServicePort();

@patch
class _IOService {
  static final SendPort _port = _newServicePort();

  static RawReceivePort? _receivePort;
  static late SendPort _replyToPort;
  static HashMap<int, Completer> _messageMap = new HashMap<int, Completer>();
  static int _id = 0;

  @patch
  static Future<Object?> _dispatch(int request, List data) {
    int id;
    do {
      id = _getNextId();
    } while (_messageMap.containsKey(id));
    final Completer completer = new Completer();
    try {
      _ensureInitialize();
      _messageMap[id] = completer;
      _port.send(<dynamic>[id, _replyToPort, request, data]);
    } catch (error) {
      _messageMap.remove(id)!.complete(error);
      if (_messageMap.length == 0) {
        _finalize();
      }
    }
    return completer.future;
  }

  static void _ensureInitialize() {
    if (_receivePort == null) {
      _receivePort = new RawReceivePort(null, 'IO Service');
      _replyToPort = _receivePort!.sendPort;
      _receivePort!.handler = (List<Object?> data) {
        assert(data.length == 2);
        _messageMap.remove(data[0])!.complete(data[1]);
        if (_messageMap.length == 0) {
          _finalize();
        }
      };
    }
  }

  static void _finalize() {
    _id = 0;
    _receivePort!.close();
    _receivePort = null;
  }

  static int _getNextId() {
    if (_id == 0x7FFFFFFF) _id = 0;
    return _id++;
  }
}
