// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

Future<int> freeIPv4AndIPv6Port() async {
  var socket =
    await ServerSocket.bind(InternetAddress.ANY_IP_V6, 0, v6Only: false);
  int port = socket.port;
  await socket.close();
  return port;
}

Future retry(Future fun(), {int maxCount: 10}) async {
  for (int i = 0; i < maxCount; i++) {
    try {
      // If there is no exception this will simply return, otherwise we keep
      // trying.
      return await fun();
    } catch (_) {}
    print("Failed to execute test closure in attempt $i "
          "(${maxCount - i} retries left).");
  }
  return await fun();
}

