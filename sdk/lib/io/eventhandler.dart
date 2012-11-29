// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_io;

class _EventHandler {
  external static void _start();
  external static _sendData(Object sender, ReceivePort receivePort, int data);
}
