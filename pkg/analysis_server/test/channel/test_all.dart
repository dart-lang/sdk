// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.channel.all;

import 'package:unittest/unittest.dart';

import 'byte_stream_channel_test.dart' as byte_stream_channel_test;
import 'web_socket_channel_test.dart' as web_socket_channel_test;


/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('computer', () {
    byte_stream_channel_test.main();
    web_socket_channel_test.main();
  });
}