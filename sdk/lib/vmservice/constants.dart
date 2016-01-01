// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

// These must be kept in sync with runtime/vm/service.cc.
class Constants {
  static const int SERVICE_EXIT_MESSAGE_ID = 0;
  static const int ISOLATE_STARTUP_MESSAGE_ID = 1;
  static const int ISOLATE_SHUTDOWN_MESSAGE_ID = 2;
}
