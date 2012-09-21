// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _EventHandler extends NativeFieldWrapperClass1 {
  _EventHandler() { }

  static void _start() {
    if (_eventHandler === null) {
      _eventHandler = new _EventHandler();
      _eventHandler._doStart();
    }
  }

  void _doStart() native "EventHandler_Start";

  static _sendData(Object sender, ReceivePort receivePort, int data) {
    if (_eventHandler !== null) {
      _eventHandler._doSendData(sender, receivePort, data);
    }
  }

  void _doSendData(Object sender, ReceivePort receivePort, int data)
      native "EventHandler_SendData";

  static _EventHandler _eventHandler;
}
