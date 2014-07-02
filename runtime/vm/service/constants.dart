// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice;

// These must be kept in sync with runtime/vm/service.cc.
class Constants {
  static const int ISOLATE_STARTUP_MESSAGE_ID = 1;
  static const int ISOLATE_SHUTDOWN_MESSAGE_ID = 2;

  // Event family ids.
  static const int EVENT_FAMILY_DEBUG = 0;

  // Event family masks.
  static const int EVENT_FAMILY_DEBUG_MASK = (1 << EVENT_FAMILY_DEBUG);
}
