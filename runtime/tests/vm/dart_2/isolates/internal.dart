// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'dart:_internal' as dart_internal;

extension SendPortSendAndExit on SendPort {
  void sendAndExit(var message) {
    dart_internal.sendAndExit(this, message);
  }
}
