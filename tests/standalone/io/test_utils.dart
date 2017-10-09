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

int lastRetryId = 0;

Future retry(Future fun(), {int maxCount: 10}) async {
  final int id = lastRetryId++;
  for (int i = 0; i < maxCount; i++) {
    try {
      // If there is no exception this will simply return, otherwise we keep
      // trying.
      return await fun();
    } catch (e, stack) {
      print("Failed to execute test closure (retry id: ${id}) in attempt $i "
          "(${maxCount - i} retries left).");
      print("Exception: ${e}");
      print("Stacktrace: ${stack}");
    }
  }
  return await fun();
}
