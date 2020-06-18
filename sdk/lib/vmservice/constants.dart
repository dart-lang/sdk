// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

// These must be kept in sync with runtime/vm/service.cc.
class Constants {
  static const int SERVICE_EXIT_MESSAGE_ID = 0;
  static const int ISOLATE_STARTUP_MESSAGE_ID = 1;
  static const int ISOLATE_SHUTDOWN_MESSAGE_ID = 2;
  static const int WEB_SERVER_CONTROL_MESSAGE_ID = 3;
  static const int SERVER_INFO_MESSAGE_ID = 4;

  /// Signals an RPC coming from native code (instead of from a websocket
  /// connection).  These calls are limited to simple request-response and do
  /// not allow arbitrary json-rpc messages.
  ///
  /// The messages are an array of length 3:
  ///   (METHOD_CALL_FROM_NATIVE, String jsonRequest, PortId replyPort).
  static const int METHOD_CALL_FROM_NATIVE = 5;
}
