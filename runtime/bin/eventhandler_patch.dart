// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _EventHandler {
  /* patch */ static void _start() {
    if (_eventHandler == null) {
      _eventHandler = new _EventHandlerImpl();
      _eventHandler._start();
    }
  }

  /* patch */ static _sendData(Object sender,
                               ReceivePort receivePort,
                               int data) {
    if (_eventHandler != null) {
      _eventHandler._sendData(sender, receivePort, data);
    }
  }

  static _EventHandlerImpl _eventHandler;
}


class _EventHandlerImpl extends NativeFieldWrapperClass1 {
  _EventHandlerImpl() { }
  void _start() native "EventHandler_Start";
  void _sendData(Object sender, ReceivePort receivePort, int data)
      native "EventHandler_SendData";
}
