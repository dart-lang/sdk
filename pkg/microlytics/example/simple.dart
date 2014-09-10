// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:microlytics/channels.dart';
import 'package:microlytics/io_channels.dart';
import 'package:microlytics/microlytics.dart';

void main(List<String> arguments) {
  // Create the channel that will be used to communicate to analytics.
  var channel = new RateLimitingBufferedChannel(
      new HttpClientChannel(), packetsPerSecond: 1.0);

  if (arguments.length != 1) {
    print("usage: dart simple.dart GA-Client-ID");
    return;
  }
  final String clientID = arguments.single;

  // Create the logger.
  var lg = new AnalyticsLogger(channel, "555", clientID, "test", "1.2");

  // Send some messages.
  lg.logAnonymousEvent("hello", "world");
  lg.logAnonymousTiming("loader", "var", 42);
}