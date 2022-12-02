// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'package:expect/expect.dart';

final protectedStreams = [
  'VM',
  'Isolate',
  'Debug',
  'GC',
  '_Echo',
  'HeapSnapshot',
  'Logging',
  'Timeline',
  'Profiler',
  '_aStreamThatStartsWithAnUnderScore'
];

main() {
  for (final protectedStream in protectedStreams) {
    Expect.throws(
      () {
        postEvent('theEvent', {'the': 'data'}, stream: protectedStream);
      },
      (_) => true,
      'Should not allow posting to $protectedStream protected stream',
    );
  }

  // The Extension stream in not protected so calling this should not fail
  postEvent('theEvent', {'the': 'data'}, stream: 'Extension');

  // Should be allowed to post to a non-protecvted custom stream
  postEvent('theEvent', {'the': 'data'}, stream: 'someCustomStream');
}
