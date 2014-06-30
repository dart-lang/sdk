// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:nativewrappers';

patch class _EventHandler {
  /* patch */ static void _sendData(Object sender,
                                    SendPort sendPort,
                                    int data)
      native "EventHandler_SendData";
}

