// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <VMTest>[
  (VM vm) async {
    // Simple heartbeat test to ensure we can fetch Observatory resources.
    var heartBeatUrl =
        serviceHttpAddress + '/third_party/trace_viewer_full.html';
    print('Trying to fetch $heartBeatUrl');
    HttpClient client = new HttpClient();
    HttpClientRequest request = await client.getUrl(Uri.parse(heartBeatUrl));
    HttpClientResponse response = await request.close();
    expect(response.statusCode, 200);
    await response.drain();
  }
];

main(args) async => runVMTests(
      args, tests,
      // TODO(bkonyi): DDS doesn't forward Observatory assets properly yet.
      enableDds: false,
    );
