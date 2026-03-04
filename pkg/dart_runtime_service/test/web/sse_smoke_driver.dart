// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file must be compiled for changes to be picked up.
//
// Run the following command from the root of this package if this file is
// updated:
//
// dart compile js --no-source-maps --minify -o test/web/sse_smoke_driver.dart.js test/web/sse_smoke_driver.dart

import 'package:async/async.dart';
import 'package:sse/client/sse_client.dart';

Future<void> main() async {
  // Connect to test server
  final channel = SseClient('/test');
  final testerStream = StreamQueue<String>(channel.stream);

  // Connect to Dart Runtime Service
  final serviceUri = await testerStream.next;
  try {
    final client = SseClient(serviceUri);
    await client.onConnected;
    channel.sink.add('Success');
    client.close();
  } catch (e) {
    channel.sink.add('Error: $e');
  }
  channel.close();
}
